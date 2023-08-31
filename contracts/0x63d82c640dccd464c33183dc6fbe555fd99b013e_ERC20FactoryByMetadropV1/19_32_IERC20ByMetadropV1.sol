// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IConfigStructures} from "../../Global/IConfigStructures.sol";
import {IERC20ConfigByMetadropV1} from "./IERC20ConfigByMetadropV1.sol";

/**
 * @dev Metadrop core ERC-20 contract, interface
 */
interface IERC20ByMetadropV1 is
  IERC20,
  IERC20ConfigByMetadropV1,
  IERC20Metadata,
  IConfigStructures
{
  struct SocialLinks {
    string linkType;
    string link;
  }

  event AutoSwapThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

  event ProjectTaxBasisPointsChanged(
    uint256 oldBuyBasisPoints,
    uint256 newBuyBasisPoints,
    uint256 oldSellBasisPoints,
    uint256 newSellBasisPoints
  );

  event MetadropTaxBasisPointsChanged(
    uint256 oldBuyBasisPoints,
    uint256 newBuyBasisPoints,
    uint256 oldSellBasisPoints,
    uint256 newSellBasisPoints
  );

  event LiquidityPoolCreated(address addedPool);

  event LiquidityPoolAdded(address addedPool);

  event LiquidityPoolRemoved(address removedPool);

  event InitialLiquidityAdded(uint256 tokenA, uint256 tokenB, uint256 lpToken);

  event LiquidityLocked();

  event RevenueAutoSwap();

  event SetLimitsEnabled(bool enabled);

  event TreasuryUpdated(address treasury);

  event UnlimitedAddressAdded(address addedUnlimted);

  event UnlimitedAddressRemoved(address removedUnlimted);

  /**
   * @dev function {addInitialLiquidity}
   *
   * Add initial liquidity to the uniswap pair
   *
   * @param lockerFee_ The locker fee in wei. This must match the required fee from the external locker contract.
   */
  function addInitialLiquidity(uint256 lockerFee_) external payable;

  /**
   * @dev function {isLiquidityPool}
   *
   * Return if an address is a liquidity pool
   *
   * @param queryAddress_ The address being queried
   * @return bool The address is / isn't a liquidity pool
   */
  function isLiquidityPool(address queryAddress_) external view returns (bool);

  /**
   * @dev function {addLiquidityPool} onlyTaxAdmin
   *
   * Allows the tax admin to add a liquidity pool to the pool enumerable set
   *
   * @param newLiquidityPool_ The address of the new liquidity pool
   */
  function addLiquidityPool(address newLiquidityPool_) external;

  /**
   * @dev function {removeLiquidityPool} onlyTaxAdmin
   *
   * Allows the tax admin to remove a liquidity pool
   *
   * @param removedLiquidityPool_ The address of the old removed liquidity pool
   */
  function removeLiquidityPool(address removedLiquidityPool_) external;

  /**
   * @dev function {isUnlimited}
   *
   * Return if an address is unlimited (is not subject to per txn and per wallet limits)
   *
   * @param queryAddress_ The address being queried
   * @return bool The address is / isn't unlimited
   */
  function isUnlimited(address queryAddress_) external view returns (bool);

  /**
   * @dev function {addUnlimited} onlyTaxAdmin
   *
   * Allows the tax admin to add an unlimited address
   *
   * @param newUnlimited_ The address of the new unlimited address
   */
  function addUnlimited(address newUnlimited_) external;

  /**
   * @dev function {removeUnlimited} onlyTaxAdmin
   *
   * Allows the tax admin to remove an unlimited address
   *
   * @param removedUnlimited_ The address of the old removed unlimited address
   */
  function removeUnlimited(address removedUnlimited_) external;

  /**
   * @dev function {setLimitsEnabledStatus} onlyTaxAdmin
   *
   * Allows the tax admin to enable / disable tokens per txn and per holder validation.
   *
   * @param enabled_ Should limits be on?
   */
  function setLimitsEnabledStatus(bool enabled_) external;

  /**
   * @dev function {setProjectTreasury} onlyTaxAdmin
   *
   * Allows the tax admin to set the treasury address
   *
   * @param projectTreasury_ New treasury address
   */
  function setProjectTreasury(address projectTreasury_) external;

  /**
   * @dev function {setSwapThresholdBasisPoints} onlyTaxAdmin
   *
   * Allows the tax admin to set the autoswap threshold
   *
   * @param swapThresholdBasisPoints_ New swap threshold in basis points
   */
  function setSwapThresholdBasisPoints(
    uint16 swapThresholdBasisPoints_
  ) external;

  /**
   * @dev function {withdrawETH} onlyOwner
   *
   * Allows the owner to withdraw ETH
   *
   * @param amount_ The amount to withdraw
   */
  function withdrawETH(uint256 amount_) external;

  /**
   * @dev function {withdrawERC20} onlyOwner
   *
   * A withdraw function to allow ERC20s to be withdrawn.
   *
   * @param token_ The address of the token being withdrawn
   * @param amount_ The amount to withdraw
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /**
   * @dev function {setProjectTaxRates} onlyTaxAdmin
   *
   * Change the tax rates, subject to max rate
   *
   * @param newProjectBuyTaxBasisPoints_ The new buy tax rate
   * @param newProjectSellTaxBasisPoints_ The new sell tax rate
   */
  function setProjectTaxRates(
    uint16 newProjectBuyTaxBasisPoints_,
    uint16 newProjectSellTaxBasisPoints_
  ) external;

  /**
   * @dev function {setMetadropTaxRates} onlyTaxAdmin
   *
   * Change the tax rates, subject to max rate and minimum tax period.
   *
   * @param newMetadropBuyTaxBasisPoints_ The new buy tax rate
   * @param newMetadropSellTaxBasisPoints_ The new sell tax rate
   */
  function setMetadropTaxRates(
    uint16 newMetadropBuyTaxBasisPoints_,
    uint16 newMetadropSellTaxBasisPoints_
  ) external;
}