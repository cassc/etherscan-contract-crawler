// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { CREATE3 } from "solmate/utils/CREATE3.sol";

contract Create3Deployer {
    function deployContract(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) external returns (address deployed) {
        deployed = CREATE3.deploy(salt, creationCode, value);
    }

    function getDeployed(bytes32 salt) external view returns (address deployed) {
        deployed = CREATE3.getDeployed(salt);
    }
}