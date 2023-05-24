// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRoyaltyFeeRegistry {
    function royaltyFeeInfoCollection(address collection) external view returns (address, address, uint256);
}