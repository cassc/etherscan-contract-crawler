// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { INFTFactory } from "./INFTFactory.sol";

interface IPassClaim {
    struct NFTItem {
        address collection;
        uint256 tokenId;
        uint256 deduplicationId;
        uint256 maxUsage;
    }

    function mintItem(
        NFTItem[] calldata nftItems,
        INFTFactory.MintItemParams calldata params,
        bytes calldata signature
    ) external payable;
}