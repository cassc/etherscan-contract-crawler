// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPUtilitiesInterface {
    function purchaseIncubator() external;

    function purchaseMergerOrb() external;

    function transferOwnership(address) external;

    function balanceOf(address, uint256) external returns (uint256);

    function burn(uint256, uint256) external;

    function airdrop(
        address,
        uint256,
        uint256
    ) external;
}