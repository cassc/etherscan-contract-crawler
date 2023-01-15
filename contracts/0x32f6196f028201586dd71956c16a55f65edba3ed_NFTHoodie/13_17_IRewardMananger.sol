// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../base/Structs.sol";

interface IRewardMananger {
    function calcReward(uint256 amount, bool forCollection) external view returns (uint256);

    function addReward(NFT memory nft, bool forCollection) external payable;

    function addReward(
        NFT memory nft,
        bool forCollection,
        address token,
        uint256 amount
    ) external;
}