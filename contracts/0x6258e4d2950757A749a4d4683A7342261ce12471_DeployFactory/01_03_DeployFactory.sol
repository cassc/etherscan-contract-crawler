// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IDeployFactory.sol";
import "./utils/CREATE3.sol";

contract DeployFactory is IDeployFactory {

    event contractAddress(address indexed newaddr);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value) external override {
        address newContract = CREATE3.deploy(salt, creationCode, value);

        emit contractAddress(newContract);
    }

    function getAddress(bytes32 salt) public view override returns (address) {
        return CREATE3.getDeployed(salt);
    }
}