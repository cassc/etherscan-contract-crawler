// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IERC20.sol";
interface INineLives is IERC20 {
    struct FeeRate {
        uint16 totalFeeRate;
        uint16 LPFeeRate;
        uint16 MarketingFeeRate;
        uint16 ProofFeeRate;
    }

    struct PurchasingInfo {
        uint256 purchaseId;
        mapping(uint256 => uint256) purchaseTime;
        mapping(uint256 => uint256) purchaseAmount;
    }

    struct Param {
        address pairToken;
        address routerAddr;
        address marketingWallet;
        address proofRevenueWallet;
        address proofRewardsWallet;
        address proofAdminWallet;
        address[] wallets;   // 6 % for 6 wallets.
        FeeRate firstSellFee;   // fee when users sell tokens in 24 hours after purchasing
        FeeRate afterSellFee;   // fee when users sell normally
        FeeRate buyFee;         // fee when users buy normally.
        uint16 maxSellFee;
        uint16 maxBuyFee;
    }
}