// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployMultiSigWallet} from "../../script/DeployMultiSigWallet.s.sol";

contract MultiSigWalletTest is Test{
    function setUp() external{
        DeployMultiSigWallet deployer = new DeployMultiSigWallet();
        deployer.run();
    }
}

