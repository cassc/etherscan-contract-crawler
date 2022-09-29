// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface ICreator {
    function create(
        uint8,
        address,
        uint256,
        address,
        address,
        string calldata,
        string calldata,
        uint8
    ) external returns (address, address);

    function setAdmin(address) external returns (bool);

    function setMarketPlace(address) external returns (bool);
}