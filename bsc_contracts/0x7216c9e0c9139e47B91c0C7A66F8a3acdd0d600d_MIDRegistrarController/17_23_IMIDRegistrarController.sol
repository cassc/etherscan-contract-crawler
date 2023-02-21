// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/*
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
interface IMIDRegistrarController {
    function rentPrice(string memory name, uint duration) external view returns(uint);

    function available(string memory name) external view returns(bool);

    function makeCommitment(string memory name, address owner, bytes32 secret) pure external returns(bytes32);

    function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure external returns(bytes32);

    function commit(bytes32 commitment) external;

    function register(string calldata name, address owner, uint duration, bytes32 secret) external payable;

    function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) external payable;

    function renew(string calldata name, uint duration) external payable;
}