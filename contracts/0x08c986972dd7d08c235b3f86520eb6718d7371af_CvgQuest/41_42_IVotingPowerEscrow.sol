// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotingPowerEscrow {
    function create_lock(uint256 tokenId, uint256 value, uint256 unlockTime) external;

    function increase_amount(uint256 tokenId, uint256 value) external;

    function increase_unlock_time(uint256 tokenId, uint256 unlockTime) external;

    function withdraw(uint256 tokenId) external;

    function total_supply() external returns (uint256);

    function balanceOf(uint256 tokenId) external view returns (uint256);
}