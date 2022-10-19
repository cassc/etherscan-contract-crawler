// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IStagingBox.sol";
import "../interfaces/IConvertibleBondBox.sol";

struct NumFixedPoint {
    uint256 value;
    uint256 decimals;
}

struct StagingDataIBO {
    NumFixedPoint lendSlipSupply;
    NumFixedPoint borrowSlipSupply;
    NumFixedPoint safeTrancheBalance;
    NumFixedPoint riskTrancheBalance;
    NumFixedPoint stableTokenBalance;
    NumFixedPoint safeTrancheCollateral;
    NumFixedPoint riskTrancheCollateral;
    NumFixedPoint tvlBorrow;
    NumFixedPoint tvlLend;
}

struct StagingDataActive {
    NumFixedPoint lendSlipSupply;
    NumFixedPoint borrowSlipSupply;
    NumFixedPoint safeTrancheBalance;
    NumFixedPoint riskTrancheBalance;
    NumFixedPoint safeSlipBalance;
    NumFixedPoint riskSlipBalance;
    NumFixedPoint stableTokenBalanceBorrow;
    NumFixedPoint stableTokenBalanceLend;
    NumFixedPoint safeTrancheCollateral;
    NumFixedPoint riskTrancheCollateral;
    NumFixedPoint safeSlipCollateral;
    NumFixedPoint riskSlipCollateral;
    NumFixedPoint tvlBorrow;
    NumFixedPoint tvlLend;
}

struct CBBDataActive {
    NumFixedPoint safeSlipSupply;
    NumFixedPoint riskSlipSupply;
    NumFixedPoint repaidSafeSlips;
    NumFixedPoint safeTrancheBalance;
    NumFixedPoint riskTrancheBalance;
    NumFixedPoint stableTokenBalance;
    NumFixedPoint safeTrancheCollateral;
    NumFixedPoint riskTrancheCollateral;
    NumFixedPoint currentPrice;
    NumFixedPoint tvlBorrow;
    NumFixedPoint tvlLend;
}

struct CBBDataMature {
    NumFixedPoint safeSlipSupply;
    NumFixedPoint riskSlipSupply;
    NumFixedPoint repaidSafeSlips;
    NumFixedPoint safeTrancheBalance;
    NumFixedPoint riskTrancheBalance;
    NumFixedPoint zPenaltyTrancheBalance;
    NumFixedPoint stableTokenBalance;
    NumFixedPoint safeTrancheCollateral;
    NumFixedPoint riskTrancheCollateral;
    NumFixedPoint zPenaltyTrancheCollateral;
    NumFixedPoint currentPrice;
    NumFixedPoint tvlBorrow;
    NumFixedPoint tvlLend;
}

interface IConvertiblesDVLens {
    /**
     * @dev provides the stats for Staging Box in IBO period
     * @param _stagingBox The staging box tied to the Convertible Bond
     * Requirements:
     */

    function viewStagingStatsIBO(IStagingBox _stagingBox)
        external
        view
        returns (StagingDataIBO memory);

    /**
     * @dev provides the stats for StagingBox after the IBO is completed
     * @param _stagingBox The staging box tied to the Convertible Bond
     * Requirements:
     */

    function viewStagingStatsActive(IStagingBox _stagingBox)
        external
        view
        returns (StagingDataActive memory);

    /**
     * @dev provides the stats for CBB after IBO
     * @param _convertibleBondBox The CBB being queried
     * Requirements:
     */

    function viewCBBStatsActive(IConvertibleBondBox _convertibleBondBox)
        external
        view
        returns (CBBDataActive memory);

    /**
     * @dev provides the stats for CBB after maturity
     * @param _convertibleBondBox The CBB being queried
     * Requirements:
     */

    function viewCBBStatsMature(IConvertibleBondBox _convertibleBondBox)
        external
        view
        returns (CBBDataMature memory);
}