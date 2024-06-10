pragma solidity ^0.8.18;

import "../lib/forge-std/src/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 minApproval;
        address[] owners;
    }

    struct NetworkConfig2 {
        uint256 minApproval;
        uint256 whatEverNum;
    }


    NetworkConfig public activeNetworkConfig;
    NetworkConfig2 public activeNetworkConfig2;

    constructor() {
        activeNetworkConfig = getDefaultNetworkConfig();
        activeNetworkConfig2 = getDefaultNetworkConfig2();
    }

    function getDefaultNetworkConfig() public pure returns (NetworkConfig memory){
        address[] memory hardcodedOwnerAddresses = new address[](3);
        hardcodedOwnerAddresses[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        hardcodedOwnerAddresses[1] = 0xA70E68936d0B7FC8512C50107a3A3bf396a32B24;
        hardcodedOwnerAddresses[2] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        return NetworkConfig({
            minApproval: 3,
            owners: hardcodedOwnerAddresses
        });
    }

    function getDefaultNetworkConfig2() public returns (NetworkConfig2 memory){
        address[] memory hardcodedOwnerAddresses = new address[](3);
        return NetworkConfig2({
            minApproval: 3,
            whatEverNum: 3
        });
    }

    
}
