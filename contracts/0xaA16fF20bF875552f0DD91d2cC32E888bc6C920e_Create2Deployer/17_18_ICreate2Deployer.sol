// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ICreate2Deployer
 * @dev ICreate2Deployer interface
 **/

interface ICreate2Deployer {
    event DeployedToken(
        address newContract,
        bytes32 salt,
        bytes32 bytecodeHash,
        string name,
        string symbol
    );

    event Deployed(address newContract, bytes32 salt, bytes32 bytecodeHash);

    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode,
        bytes memory initializer
    ) external returns (address);

    function deployToken(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode,
        bytes memory initializer
    ) external returns (address);

    function computeAddress(bytes32 salt, bytes32 bytecodeHash)
        external
        view
        returns (address);

    function withdraw(uint256 amount) external returns (bool);
}