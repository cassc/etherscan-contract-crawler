// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Actions that the ship can take
interface IBuyEvents {
    event NFTBought(
        uint256 timestamp,
        uint256 price,
        address nftContract,
        uint256 nftTokenID
    );
}