// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {DeployMultiSigWallet} from "../../script/DeployMultiSigWallet.s.sol";
import {MultiSigWallet} from "../../src/MultiSigWallet.sol";
import {console} from "../../lib/forge-std/src/console.sol";

contract MultiSigWalletTest is Test {
    event ReceivedEth(uint256 indexed amount);
    MultiSigWallet public multiSigWallet;
    address public RANDOM_PERSON = makeAddr("players");
    address private TARGET_ADDRESS = 0xf6a20a9F06F1739f83dfC35E36d2Ba882e45fA3D; // same as owner_1
    address private OWNER_1 = 0xf6a20a9F06F1739f83dfC35E36d2Ba882e45fA3D;
    uint256 private STARTING_OWNER_1_BALANCE = 10;
    address private OWNER_2 = 0xA70E68936d0B7FC8512C50107a3A3bf396a32B24;
    address private OWNER_3 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    uint256 private ETH_SEND_AMOUNT = 3;

    function setUp() external {
        DeployMultiSigWallet deployer = new DeployMultiSigWallet();
        MultiSigWallet multiSigWalletReturned = deployer.run();
        multiSigWallet = multiSigWalletReturned;
    }

    function testIfMinApprovalInitTo3() public view {
        assertEq(multiSigWallet.getMinApproval(), 3);
    }

    function testSendRandomData() public {
        vm.expectRevert(MultiSigWallet.MultiSigWallet__TxFail.selector);
        //WHY, it reverts but not match the revert error, the test is still passed.
        (bool success, ) = address(multiSigWallet).call("helloWorld");
        console.log(success);
    }

    modifier sendRequestTxFromOwner() {
        vm.startPrank(OWNER_1);
        uint256 valueSentByOwner1 = 4;
        vm.deal(OWNER_1, STARTING_OWNER_1_BALANCE);
        console.log("before owner1 sending money", OWNER_1.balance);
        (bool success, ) = address(multiSigWallet).call{
            value: valueSentByOwner1
        }("");
        require(success, "Transfer failed");
        address targetAddress = TARGET_ADDRESS; //
        multiSigWallet.requestTx(targetAddress, ETH_SEND_AMOUNT);

        console.log("after owner1 sending money", OWNER_1.balance);
        _;
    }

    function testSendEth() public {
        vm.startPrank(OWNER_1);
        uint256 valueSentByOwner1 = 4;
        vm.deal(OWNER_1, STARTING_OWNER_1_BALANCE);
        console.log(OWNER_1.balance);
        vm.expectEmit(true, false, false, false);
        emit ReceivedEth(4);
        (bool success, bytes memory returnData) = address(multiSigWallet).call{
            value: valueSentByOwner1
        }("");
        console.logBytes(returnData); // Log any return data for debugging
        console.log(success);
        console.log(OWNER_1.balance);
        //My question, why do vm.expectEmit will influece the "success"',
        //does not make sense as events should not affect the succeed of tx.
        require(success, "Transfer failed!!!!!!!!!!!!!");
    }

    function testNotOwner() public {
        vm.startPrank(RANDOM_PERSON);
        address targetAddress = TARGET_ADDRESS; //
        vm.expectRevert(MultiSigWallet.MultiSigWallet__NotOwner.selector);
        multiSigWallet.requestTx(targetAddress, ETH_SEND_AMOUNT);
        vm.stopPrank();
    }

    function testTxIndexNotExist() public sendRequestTxFromOwner {
        vm.expectRevert(MultiSigWallet.MultiSigWallet__NoTxIndex.selector);
        multiSigWallet.approveTx(10);
        vm.stopPrank();
    }

    function testRequestTxUpdateTxIndex() public sendRequestTxFromOwner {
        assertEq(multiSigWallet.getLatestTxIndex(), 1);
    }

    function testRequestTxUpdateTargetAddress() public sendRequestTxFromOwner {
        assertEq(multiSigWallet.getTargetAddressByTxIndex(1), TARGET_ADDRESS);
    }

    function testRequestTxUpdateIsExist() public sendRequestTxFromOwner {
        assertEq(multiSigWallet.getIsExistByTxIndex(1), true);
    }

    function testRequestTxUpdateApprovedOwners() public sendRequestTxFromOwner {
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1).length, 1);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1)[0], OWNER_1);
    }

    function testApproveTxUpdateApprovedOwners() public sendRequestTxFromOwner {
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1).length, 2);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1)[1], OWNER_2);
        vm.stopPrank();
    }

    function testOwnerAlreadyAproved() public sendRequestTxFromOwner {
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        vm.expectRevert(
            MultiSigWallet.MultiSigWallet__OwnerAlreadyApproved.selector
        );
        multiSigWallet.approveTx(1);
        vm.stopPrank();
    }

    function testNotEnoughApproval() public sendRequestTxFromOwner {
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1).length, 2);
        assertEq(multiSigWallet.getApprovedOwnersByTxIndex(1)[1], OWNER_2);
        vm.expectRevert(
            MultiSigWallet.MultiSigWallet__NotEnoughApproval.selector
        );
        multiSigWallet.executeTx(1);
        vm.stopPrank();
    }

    function testExecuteSuccess() public sendRequestTxFromOwner {
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        vm.stopPrank();
        vm.startPrank(OWNER_3);
        multiSigWallet.approveTx(1);
        multiSigWallet.executeTx(1);
        //three approval, should be enough
        vm.stopPrank();
        console.log("owner1 after execute", OWNER_1.balance);
        assertEq(multiSigWallet.getBalance(), 1);
    }

    function testRevoke() public sendRequestTxFromOwner {
        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        vm.stopPrank();
        vm.startPrank(OWNER_3);
        multiSigWallet.approveTx(1);
        vm.stopPrank();
        // Get the approved owners and log them
        address[] memory approvedOwnerList = multiSigWallet
            .getApprovedOwnersByTxIndex(1);
        console.log("Before revoke, approved owners:");
        for (uint256 i = 0; i < approvedOwnerList.length; i++) {
            console.log(approvedOwnerList[i]);
        }

        vm.startPrank(OWNER_2);
        multiSigWallet.revokeApproval(1);
        vm.stopPrank();
        approvedOwnerList = multiSigWallet.getApprovedOwnersByTxIndex(1);
        console.log("After revoke, approved owners:");
        for (uint256 i = 0; i < approvedOwnerList.length; i++) {
            console.log(approvedOwnerList[i]);
        }
        assertEq(
            approvedOwnerList.length,
            2,
            "There should be exactly 2 approved owners after revoke"
        );
        assertEq(
            approvedOwnerList[0],
            OWNER_1,
            "First approved owner should be OWNER_1"
        );
        assertEq(
            approvedOwnerList[1],
            OWNER_3,
            "Second approved owner should be OWNER_3"
        );
        vm.expectRevert(
            MultiSigWallet.MultiSigWallet__NotEnoughApproval.selector
        );
        vm.startPrank(OWNER_2);
        multiSigWallet.executeTx(1);
        vm.stopPrank();

        vm.startPrank(OWNER_2);
        multiSigWallet.approveTx(1);
        multiSigWallet.executeTx(1);
        vm.stopPrank();

        vm.startPrank(OWNER_2);
        vm.expectRevert(
            MultiSigWallet.MultiSigWallet__AlreadyExecuted.selector
        );
        multiSigWallet.executeTx(1);
        vm.stopPrank();
    }
}
