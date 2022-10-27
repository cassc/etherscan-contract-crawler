// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {IAelinPool} from "./IAelinPool.sol";

interface IAelinUpFrontDeal {
    struct UpFrontDealData {
        string name;
        string symbol;
        address purchaseToken;
        address underlyingDealToken;
        address holder;
        address sponsor;
        uint256 sponsorFee;
        bytes32 merkleRoot;
        string ipfsHash;
    }

    struct UpFrontDealConfig {
        uint256 underlyingDealTokenTotal;
        uint256 purchaseTokenPerDealToken;
        uint256 purchaseRaiseMinimum;
        uint256 purchaseDuration;
        uint256 vestingPeriod;
        uint256 vestingCliffPeriod;
        bool allowDeallocation;
    }

    event CreateUpFrontDeal(
        address indexed dealAddress,
        string name,
        string symbol,
        address purchaseToken,
        address underlyingDealToken,
        address indexed holder,
        address indexed sponsor,
        uint256 sponsorFee,
        bytes32 merkleRoot,
        string ipfsHash
    );

    event CreateUpFrontDealConfig(
        address indexed dealAddress,
        uint256 underlyingDealTokenTotal,
        uint256 purchaseTokenPerDealToken,
        uint256 purchaseRaiseMinimum,
        uint256 purchaseDuration,
        uint256 vestingPeriod,
        uint256 vestingCliffPeriod,
        bool allowDeallocation
    );

    event DepositDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed depositor,
        uint256 underlyingDealTokenAmount
    );

    event DealFullyFunded(
        address upFrontDealAddress,
        uint256 timestamp,
        uint256 purchaseExpiryTimestamp,
        uint256 vestingCliffExpiryTimestamp,
        uint256 vestingExpiryTimestamp
    );

    event WithdrewExcess(address UpFrontDealAddress, uint256 amountWithdrawn);

    event AcceptDeal(
        address indexed user,
        uint256 amountPurchased,
        uint256 totalPurchased,
        uint256 amountDealTokens,
        uint256 totalDealTokens
    );

    event ClaimDealTokens(address indexed user, uint256 amountMinted, uint256 amountPurchasingReturned);

    event SponsorClaim(address indexed sponsor, uint256 amountMinted);

    event HolderClaim(
        address indexed holder,
        address purchaseToken,
        uint256 amountClaimed,
        address underlyingToken,
        uint256 underlyingRefund,
        uint256 timestamp
    );

    event FeeEscrowClaim(address indexed aelinFeeEscrow, address indexed underlyingTokenAddress, uint256 amount);

    event ClaimedUnderlyingDealToken(address indexed user, address underlyingToken, uint256 amountClaimed);

    event PoolWith721(address indexed collectionAddress, uint256 purchaseAmount, bool purchaseAmountPerToken);

    event PoolWith1155(
        address indexed collectionAddress,
        uint256 purchaseAmount,
        bool purchaseAmountPerToken,
        uint256[] tokenIds,
        uint256[] minTokensEligible
    );

    event SetHolder(address indexed holder);

    event Vouch(address indexed voucher);

    event Disavow(address indexed voucher);
}