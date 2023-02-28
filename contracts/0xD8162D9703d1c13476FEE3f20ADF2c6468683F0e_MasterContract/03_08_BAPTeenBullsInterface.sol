// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPTeenBullsInterface {
    function generateTeenBull() external;

    function generateMergerOrb() external;

    function ownerOf(uint256) external view returns (address);

    function burnTeenBull(uint256) external;

    function airdrop(address, uint256) external;

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;
}