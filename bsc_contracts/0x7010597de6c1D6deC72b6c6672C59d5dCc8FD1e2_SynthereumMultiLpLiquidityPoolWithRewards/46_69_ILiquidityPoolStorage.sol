// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IStandardERC20} from '../../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  FixedPoint
} from '../../../../@uma/core/contracts/common/implementation/FixedPoint.sol';

interface ISynthereumLiquidityPoolStorage {
  // Describe role structure
  struct Roles {
    address admin;
    address maintainer;
    address liquidityProvider;
  }

  // Describe fee data structure
  struct FeeData {
    // Fees charged when a user mints, redeem and exchanges tokens
    FixedPoint.Unsigned feePercentage;
    // Recipient receiving fees
    address[] feeRecipients;
    // Proportion for each recipient
    uint32[] feeProportions;
  }

  // Describe fee structure
  struct Fee {
    // Fee data structure
    FeeData feeData;
    // Used with individual proportions to scale values
    uint256 totalFeeProportions;
  }

  struct Storage {
    // Synthereum finder
    ISynthereumFinder finder;
    // Synthereum version
    uint8 version;
    // Collateral token
    IStandardERC20 collateralToken;
    // Synthetic token
    IMintableBurnableERC20 syntheticToken;
    // Overcollateralization percentage
    FixedPoint.Unsigned overCollateralization;
    // Fees
    Fee fee;
    // Price identifier
    bytes32 priceIdentifier;
  }

  struct LPPosition {
    // Collateral used for collateralize tokens
    FixedPoint.Unsigned totalCollateralAmount;
    // Number of tokens collateralized
    FixedPoint.Unsigned tokensCollateralized;
  }

  struct Liquidation {
    // Percentage of overcollateralization to which a liquidation can triggered
    FixedPoint.Unsigned collateralRequirement;
    // Percentage of reward for correct liquidation by a liquidator
    FixedPoint.Unsigned liquidationReward;
  }

  struct FeeStatus {
    // Track the fee gained to be withdrawn by an address
    mapping(address => FixedPoint.Unsigned) feeGained;
    // Total amount of fees to be withdrawn
    FixedPoint.Unsigned totalFeeAmount;
  }

  struct Shutdown {
    // Timestamp of execution of shutdown
    uint256 timestamp;
    // Price of the pair at the moment of the shutdown
    FixedPoint.Unsigned price;
  }
}