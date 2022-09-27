// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILLCGift {
    function claimers(address) external view returns (uint256);

    function claimStatuses(address) external view returns (uint256);

    function addClaimer(address, uint256) external;
}