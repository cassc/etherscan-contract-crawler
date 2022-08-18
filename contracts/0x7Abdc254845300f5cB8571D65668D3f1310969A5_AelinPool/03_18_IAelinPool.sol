// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IAelinPool {
    struct PoolData {
        string name;
        string symbol;
        uint256 purchaseTokenCap;
        address purchaseToken;
        uint256 duration;
        uint256 sponsorFee;
        uint256 purchaseDuration;
        address[] allowListAddresses;
        uint256[] allowListAmounts;
        NftCollectionRules[] nftCollectionRules;
    }

    // collectionAddress should be unique, otherwise will override
    struct NftCollectionRules {
        // if 0, then unlimited purchase
        uint256 purchaseAmount;
        address collectionAddress;
        // if true, then `purchaseAmount` is per token
        // else `purchaseAmount` is per account regardless of the NFTs held
        bool purchaseAmountPerToken;
        // both variables below are only applicable for 1155
        uint256[] tokenIds;
        // min number of tokens required for participating
        uint256[] minTokensEligible;
    }

    struct NftPurchaseList {
        address collectionAddress;
        uint256[] tokenIds;
    }
}