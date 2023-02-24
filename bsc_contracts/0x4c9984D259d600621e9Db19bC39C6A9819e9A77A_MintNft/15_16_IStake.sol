pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
interface IStake {
    function stakeOwner(
        address nftOwner,
        bool didEnd,
        uint256 tokenId,
        uint256 endTime,
        uint256 fullStaked
    ) external;
}