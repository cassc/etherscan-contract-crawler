// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IFeeDistributor } from "./IFeeDistributor.sol";

interface IIncinerator {
    struct NFTItem {
        address collection;
        uint256 tokenId;
    }

    struct Message {
        bytes32 hash;
        bytes signature;
    }

    function burnItems(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        bytes calldata signature
    ) external payable;

    function permitBurnItems(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        bytes32 messageHash,
        bytes calldata signature
    ) external payable;

    function burnItemsHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        address sender
    ) external pure returns (bytes32);
}