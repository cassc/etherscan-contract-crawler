// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {CREATE3} from "solady/utils/CREATE3.sol";

contract Deployer {
    function create3Deploy(bytes memory code, bytes32 salt, bytes memory constructorArgs) public returns (address) {
        return CREATE3.deploy(salt, abi.encodePacked(code, constructorArgs), 0);
    }

    function getDeployed(bytes32 salt) public view returns (address) {
        return CREATE3.getDeployed(salt);
    }
}