// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3ClaimRegistry {
    event SetClaimLimit(uint256 indexed claimLimit);

    function claimLimit() external view returns (uint256);

    function baseNode() external view returns (bytes32);

    function claimable(address user_) external view returns (bool);

    function claimsOf(address user_) external view returns (uint256);

    function claim(address user_) external;
}