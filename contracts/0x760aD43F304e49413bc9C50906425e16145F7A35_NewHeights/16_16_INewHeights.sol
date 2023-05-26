// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

interface INewHeightsEvent {
    event Withdrawn(address indexed to, uint256 amount);
}

interface INewHeights is INewHeightsEvent {
    function baseURI() external view returns (string memory);

    function DEFAULT_BASE_URI() external view returns (string memory);
}