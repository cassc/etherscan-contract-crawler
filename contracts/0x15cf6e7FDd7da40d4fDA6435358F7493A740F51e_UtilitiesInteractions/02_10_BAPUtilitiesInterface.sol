// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPUtilitiesInterface {
    function burn(uint256, uint256) external;

    function purchaseIncubator() external;

    function purchaseMergerOrb() external;

    function mergerOrbsPurchased() external view returns (uint256);

    function transferOwnership(address) external;

    function airdrop(
        address,
        uint256,
        uint256
    ) external;
}