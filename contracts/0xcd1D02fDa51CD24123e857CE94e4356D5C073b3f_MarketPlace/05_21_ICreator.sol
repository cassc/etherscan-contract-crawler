// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

interface ICreator {
    function create(
        address,
        uint256,
        address,
        address,
        address,
        string calldata,
        string calldata
    ) external returns (address);
}