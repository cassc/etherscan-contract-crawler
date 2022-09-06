//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../Types.sol";

library LibStorage {

    //keccak256("com.buidlhub.config.ConfigStorage");
    bytes32 constant CONFIG_STORAGE_KEY = 0xf5b4be0a744c821d14f78bf26d55a308f420d78cebbfac103f2618fba32917b9;

     //keccak256("com.buidlhub.access.AccessControls");
    bytes32 constant ACCESS_STORAGE_KEY = 0x3a83b1278d351a40f18bb9e8e77896e8c1dc812ffaed5ea63e0e837a6dae57e9;

    //keccak256("com.buidlhub.init.InitControls");
    bytes32 constant INIT_STORAGE_KEY = 0xd59dd79cfd4373c6c6547848d91fc2ea67c8aec9053f7028828216c5af1d4741;

    //============= STORAGE ACCESSORS ==========/
   
    function getConfigStorage() internal pure returns (Types.Config storage cs) {
        assembly { cs.slot := CONFIG_STORAGE_KEY }
    }

    function getAccessStorage() internal pure returns (Types.AccessControl storage acs) {
        assembly { acs.slot := ACCESS_STORAGE_KEY }
    }

    function getInitControls() internal pure returns (Types.InitControls storage ic) {
        assembly { ic.slot := INIT_STORAGE_KEY }
    }
}