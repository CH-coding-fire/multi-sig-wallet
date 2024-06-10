// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployMultiSigWallet} from "../../script/DeployMultiSigWallet.s.sol";
import {MultiSigWallet} from "../../src/MultiSigWallet.sol";
import {console} from "forge-std/console.sol";

contract MultiSigWalletTest is Test{
    MultiSigWallet public multiSigWallet;
    address public RANDOM_PERSON = makeAddr("players");
    address private TARGET_ADDRESS = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // same as owner_1
    address private OWNER_1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256 private STARTING_OWNER_1_BALANCE = 10;
    address private OWNER_2 = 0xA70E68936d0B7FC8512C50107a3A3bf396a32B24;
    address private OWNER_3 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

    uint256 private ETH_SEND_AMOUNT = 1;

    function setUp() external{
        DeployMultiSigWallet deployer = new DeployMultiSigWallet();
        (MultiSigWallet multiSigWalletReturned) = deployer.run();
        multiSigWallet = multiSigWalletReturned;
    }

    function testIfMinApprovalInitTo3() public view{
        assertEq(multiSigWallet.getMinApproval(),3);
    }

    modifier sendRequestTxFromOwner {
        vm.startPrank(OWNER_1);
        uint256 valueSentByOwner1 = 4;
        vm.deal(OWNER_1,STARTING_OWNER_1_BALANCE);
        (bool success,) = address(multiSigWallet).call{value: valueSentByOwner1}("");
        require(success, "Transfer failed");
        address targetAddress = TARGET_ADDRESS; //
        multiSigWallet.requestTx(targetAddress, ETH_SEND_AMOUNT);
        _;
    }

    function testNotOwner() public {
        vm.startPrank(RANDOM_PERSON);
        address targetAddress = TARGET_ADDRESS; //
        vm.expectRevert(MultiSigWallet.MultiSigWallet__NotOwner.selector);
        multiSigWallet.requestTx(targetAddress, ETH_SEND_AMOUNT);
        vm.stopPrank();
    }

    function testTxIndexNotExist() public sendRequestTxFromOwner{
        vm.expectRevert(MultiSigWallet.MultiSigWallet__NoTxIndex.selector);
        multiSigWallet.approveTx(10);
        vm.stopPrank();
    }

    function testRequestTxUpdateTxIndex() public sendRequestTxFromOwner{
        assertEq(multiSigWallet.getLatestTxIndex(), 1);
    }

    function testRequestTxUpdateTargetAddress() public sendRequestTxFromOwner{
        assertEq(multiSigWallet.getTargetAddressByTxIndex(1), TARGET_ADDRESS);
    }

    function testRequestTxUpdateIsExist() public sendRequestTxFromOwner{
        assertEq(multiSigWallet.getIsExistByTxIndex(1), true);
    } 

    function testRequestTxUpdateApprovedOwners() public sendRequestTxFromOwner{
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1).length, 1);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1)[0], OWNER_1);
    }

    function testApproveTxUpdateApprovedOwners() public sendRequestTxFromOwner{
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1).length, 2);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1)[1], OWNER_2);
        vm.stopPrank();
    }

    function testOwnerAlreadyAproved() public sendRequestTxFromOwner{
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        vm.expectRevert(MultiSigWallet.MultiSigWallet__OwnerAlreadyApproved.selector);
        multiSigWallet.approveTx(1);
        vm.stopPrank();
    }

    function testNotEnoughApproval() public sendRequestTxFromOwner{
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1).length, 2);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1)[1], OWNER_2);
        vm.expectRevert(MultiSigWallet.MultiSigWallet__NotEnoughApproval.selector);
        multiSigWallet.executeTx(1);
        vm.stopPrank();
    }

    function testExecuteSuccess() public sendRequestTxFromOwner{
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        vm.stopPrank();
        vm.startPrank(OWNER_3);
        multiSigWallet.approveTx(1);
        vm.stopPrank();
        console.log(OWNER_1.balance);


    }




    // function testEnoughApproval() public sendRequestTxFromOwner{
    //     vm.startPrank(OWNER_2);
    //     multiSigWallet.approveTx(1);
    //     assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1).length, 2);
    //     assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1)[1], OWNER_2);
    //     vm.stopPrank();
    //     vm.startPrank(OWNER_3);
    //     multiSigWallet.approveTx(1);
    //     assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1).length, 3);
    //     assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1)[1], OWNER_3);
    //     multiSigWallet.executeTx(1);
    // }









}

