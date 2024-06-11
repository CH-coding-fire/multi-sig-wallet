// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../lib/forge-std/src/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMultiSigWallet is Script {
    function run() public returns (MultiSigWallet) {
        // HelperConfig helperConfig = new HelperConfig();
        // (uint256 minApproval, address[] alsdkjf)
        // = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        address[] memory hardcodedOwnerAddresses = new address[](3);
        hardcodedOwnerAddresses[0] = 0xf6a20a9F06F1739f83dfC35E36d2Ba882e45fA3D;
        hardcodedOwnerAddresses[1] = 0xA70E68936d0B7FC8512C50107a3A3bf396a32B24;
        hardcodedOwnerAddresses[2] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        MultiSigWallet multiSigWallet = new MultiSigWallet(
            hardcodedOwnerAddresses,
            3
        );
        vm.stopBroadcast();
        return multiSigWallet;
    }

    function testOne() public {}
}
