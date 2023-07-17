// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBondStruct {
    struct BondParams {
        bool isStable;
        uint8 numberOfPeriod;
        uint16 composedFunction;
        address token;
        uint32 minRoi; // Min bond ROI, divide by 1000 to get the roi in %
        uint32 maxRoi; // Max bond ROI, divide by 1000 to get the roi in %
        uint128 percentageMaxCvgToMint; // Percentage maximum of the maxCvgToMint that an user can mint in one deposit
        uint128 vestingTerm; // In timestamp
        uint256 maxCvgToMint; // Limit of Max CVG to mint
    }
    struct BondPending {
        uint128 lastBlock; // Last interaction
        uint128 vesting; // vesting left
        uint256 payout; // CVG remaining to be paid
    }
    struct BondTokenView {
        uint128 lastBlock;
        uint128 term;
        uint256 claimableCvg;
        uint256 vestedCvg;
    }

    struct BondView {
        address bondAddress;
        uint40 vestingTerm;
        uint40 bondRoi;
        bool isFlexible;
        bool isValid;
        uint256 totalCvgMinted;
        uint256 maxCvgToMint;
        uint256 assetPriceUsdCvgOracle;
        uint256 assetPriceUsdAggregator;
        uint256 bondPriceAsset;
        uint256 bondPriceUsd;
        ERC20View token;
    }
    struct ERC20View {
        string token;
        address tokenAddress;
        uint256 decimals;
    }
    struct TokenVestingInfo {
        uint256 term;
        uint256 claimable;
        uint256 pending;
    }
}