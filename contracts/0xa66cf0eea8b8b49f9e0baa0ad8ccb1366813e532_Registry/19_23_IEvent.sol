// SPDX-License-Identifier: MIT
// Creator: Nullion Labs

pragma solidity 0.8.11;

interface IEvent {
    function mint(address to, uint256[] memory ticketTypes) external returns (uint256 startId);

    function pause() external;

    function unpause() external;
}