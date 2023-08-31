// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "solmate/utils/CREATE3.sol";

contract NuguFactory {
    function deploy(bytes32 salt, bytes memory creationCode) external payable returns (address deployed) {
        salt = keccak256(abi.encodePacked(msg.sender, salt));
        deployed = CREATE3.deploy(salt, creationCode, msg.value);
    }

    function getDeployed(address deployer, bytes32 salt) external view returns (address) {
        salt = keccak256(abi.encodePacked(deployer, salt));
        return CREATE3.getDeployed(salt);
    }
}