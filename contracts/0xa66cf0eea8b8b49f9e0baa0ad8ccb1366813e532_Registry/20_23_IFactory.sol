// SPDX-License-Identifier: MIT
// Creator: Nullion Labs

pragma solidity 0.8.11;

interface IFactory {
    function createEvent(
        string memory name,
        string memory symbol,
        string memory uri,
        uint256[] memory ticketTypes,
        uint256 index
    ) external returns (address eventAddress);
}