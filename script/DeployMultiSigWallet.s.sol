// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../lib/forge-std/src/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMultiSigWallet is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 minApproval, address[] alsdkjf) 
        = helperConfig.activeNetworkConfig();
        vm.startBroadcast();

        // MultiSigWallet multiSigWallet = new MultiSigWallet(
    
        // );
        
        // Optionally, return the deployed contract address (for reference)
        // return address(multiSigWallet);

        vm.stopBroadcast();
    }

    function testOne() public{

    }
}
