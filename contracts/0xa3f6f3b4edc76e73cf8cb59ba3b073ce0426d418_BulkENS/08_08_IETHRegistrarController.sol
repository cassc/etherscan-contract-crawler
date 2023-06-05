// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct Price {
    uint256 base;
    uint256 premium;
}

interface IETHRegistrarController {
    function available(string memory name) external returns (bool);

    function rentPrice(string memory name, uint256 duration) external view returns (Price memory price);

    function makeCommitment(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) external pure returns (bytes32);

    function commit(bytes32 commitment) external;

    function register(
        string calldata name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        bytes[] calldata data,
        bool reverseRecord,
        uint16 ownerControlledFuses
    ) external payable;

    function renew(string calldata name, uint256 duration) external payable;
}