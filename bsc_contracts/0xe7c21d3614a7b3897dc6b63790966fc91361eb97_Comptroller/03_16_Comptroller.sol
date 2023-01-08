// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { CTokenInterface, CErc20Interface } from "./CTokenInterfaces.sol";
import { ComptrollerErrorReporter } from "./ErrorReporter.sol";
import { Exponential } from "./Exponential.sol";
import { PriceOracle } from "./PriceOracle.sol";
import { ComptrollerInterface } from "./ComptrollerInterface.sol";
import { ComptrollerV3Storage } from "./ComptrollerStorage.sol";
import { Unitroller } from "./Unitroller.sol";
import { IFuseFeeDistributor } from "./IFuseFeeDistributor.sol";
import { IMidasFlywheel } from "../midas/strategies/flywheel/IMidasFlywheel.sol";
import { DiamondExtension, DiamondBase, LibDiamond } from "../midas/DiamondExtension.sol";
import { ComptrollerFirstExtension } from "../compound/ComptrollerFirstExtension.sol";

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 * @dev This contract should not to be deployed alone; instead, deploy `Unitroller` (proxy contract) on top of this `Comptroller` (logic/implementation contract).
 */
contract Comptroller is ComptrollerV3Storage, ComptrollerInterface, ComptrollerErrorReporter, Exponential, DiamondBase {
  /// @notice Emitted when an admin supports a market
  event MarketListed(CTokenInterface cToken);

  /// @notice Emitted when an account enters a market
  event MarketEntered(CTokenInterface cToken, address account);

  /// @notice Emitted when an account exits a market
  event MarketExited(CTokenInterface cToken, address account);

  /// @notice Emitted when close factor is changed by admin
  event NewCloseFactor(uint256 oldCloseFactorMantissa, uint256 newCloseFactorMantissa);

  /// @notice Emitted when a collateral factor is changed by admin
  event NewCollateralFactor(
    CTokenInterface cToken,
    uint256 oldCollateralFactorMantissa,
    uint256 newCollateralFactorMantissa
  );

  /// @notice Emitted when liquidation incentive is changed by admin
  event NewLiquidationIncentive(uint256 oldLiquidationIncentiveMantissa, uint256 newLiquidationIncentiveMantissa);

  /// @notice Emitted when price oracle is changed
  event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

  /// @notice Emitted when the whitelist enforcement is changed
  event WhitelistEnforcementChanged(bool enforce);

  /// @notice Emitted when auto implementations are toggled
  event AutoImplementationsToggled(bool enabled);

  /// @notice Emitted when a new RewardsDistributor contract is added to hooks
  event AddedRewardsDistributor(address rewardsDistributor);

  // closeFactorMantissa must be strictly greater than this value
  uint256 internal constant closeFactorMinMantissa = 0.05e18; // 0.05

  // closeFactorMantissa must not exceed this value
  uint256 internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

  // No collateralFactorMantissa may exceed this value
  uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

  // liquidationIncentiveMantissa must be no less than this value
  uint256 internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0

  // liquidationIncentiveMantissa must be no greater than this value
  uint256 internal constant liquidationIncentiveMaxMantissa = 1.5e18; // 1.5

  constructor(address payable _fuseAdmin) {
    fuseAdmin = _fuseAdmin;
  }

  /*** Assets You Are In ***/

  /**
   * @notice Returns the assets an account has entered
   * @param account The address of the account to pull assets for
   * @return A dynamic list with the assets the account has entered
   */
  function getAssetsIn(address account) external view returns (CTokenInterface[] memory) {
    CTokenInterface[] memory assetsIn = accountAssets[account];

    return assetsIn;
  }

  /**
   * @notice Returns whether the given account is entered in the given asset
   * @param account The address of the account to check
   * @param cToken The cToken to check
   * @return True if the account is in the asset, otherwise false.
   */
  function checkMembership(address account, CTokenInterface cToken) external view returns (bool) {
    return markets[address(cToken)].accountMembership[account];
  }

  /**
   * @notice Add assets to be included in account liquidity calculation
   * @param cTokens The list of addresses of the cToken markets to be enabled
   * @return Success indicator for whether each corresponding market was entered
   */
  function enterMarkets(address[] memory cTokens) public override returns (uint256[] memory) {
    uint256 len = cTokens.length;

    uint256[] memory results = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      CTokenInterface cToken = CTokenInterface(cTokens[i]);

      results[i] = uint256(addToMarketInternal(cToken, msg.sender));
    }

    return results;
  }

  /**
   * @notice Add the market to the borrower's "assets in" for liquidity calculations
   * @param cToken The market to enter
   * @param borrower The address of the account to modify
   * @return Success indicator for whether the market was entered
   */
  function addToMarketInternal(CTokenInterface cToken, address borrower) internal returns (Error) {
    Market storage marketToJoin = markets[address(cToken)];

    if (!marketToJoin.isListed) {
      // market is not listed, cannot join
      return Error.MARKET_NOT_LISTED;
    }

    if (marketToJoin.accountMembership[borrower] == true) {
      // already joined
      return Error.NO_ERROR;
    }

    // survived the gauntlet, add to list
    // NOTE: we store these somewhat redundantly as a significant optimization
    //  this avoids having to iterate through the list for the most common use cases
    //  that is, only when we need to perform liquidity checks
    //  and not whenever we want to check if an account is in a particular market
    marketToJoin.accountMembership[borrower] = true;
    accountAssets[borrower].push(cToken);

    // Add to allBorrowers
    if (!borrowers[borrower]) {
      allBorrowers.push(borrower);
      borrowers[borrower] = true;
      borrowerIndexes[borrower] = allBorrowers.length - 1;
    }

    emit MarketEntered(cToken, borrower);

    return Error.NO_ERROR;
  }

  /**
   * @notice Removes asset from sender's account liquidity calculation
   * @dev Sender must not have an outstanding borrow balance in the asset,
   *  or be providing necessary collateral for an outstanding borrow.
   * @param cTokenAddress The address of the asset to be removed
   * @return Whether or not the account successfully exited the market
   */
  function exitMarket(address cTokenAddress) external override returns (uint256) {
    CTokenInterface cToken = CTokenInterface(cTokenAddress);
    /* Get sender tokensHeld and amountOwed underlying from the cToken */
    (uint256 oErr, uint256 tokensHeld, uint256 amountOwed, ) = cToken.getAccountSnapshot(msg.sender);
    require(oErr == 0, "!exitMarket"); // semi-opaque error code

    /* Fail if the sender has a borrow balance */
    if (amountOwed != 0) {
      return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
    }

    /* Fail if the sender is not permitted to redeem all of their tokens */
    uint256 allowed = redeemAllowedInternal(cTokenAddress, msg.sender, tokensHeld);
    if (allowed != 0) {
      return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
    }

    Market storage marketToExit = markets[address(cToken)];

    /* Return true if the sender is not already ‘in’ the market */
    if (!marketToExit.accountMembership[msg.sender]) {
      return uint256(Error.NO_ERROR);
    }

    /* Set cToken account membership to false */
    delete marketToExit.accountMembership[msg.sender];

    /* Delete cToken from the account’s list of assets */
    // load into memory for faster iteration
    CTokenInterface[] memory userAssetList = accountAssets[msg.sender];
    uint256 len = userAssetList.length;
    uint256 assetIndex = len;
    for (uint256 i = 0; i < len; i++) {
      if (userAssetList[i] == cToken) {
        assetIndex = i;
        break;
      }
    }

    // We *must* have found the asset in the list or our redundant data structure is broken
    assert(assetIndex < len);

    // copy last item in list to location of item to be removed, reduce length by 1
    CTokenInterface[] storage storedList = accountAssets[msg.sender];
    storedList[assetIndex] = storedList[storedList.length - 1];
    storedList.pop();

    // If the user has exited all markets, remove them from the `allBorrowers` array
    if (storedList.length == 0) {
      allBorrowers[borrowerIndexes[msg.sender]] = allBorrowers[allBorrowers.length - 1]; // Copy last item in list to location of item to be removed
      allBorrowers.pop(); // Reduce length by 1
      borrowerIndexes[allBorrowers[borrowerIndexes[msg.sender]]] = borrowerIndexes[msg.sender]; // Set borrower index of moved item to correct index
      borrowerIndexes[msg.sender] = 0; // Reset sender borrower index to 0 for a gas refund
      borrowers[msg.sender] = false; // Tell the contract that the sender is no longer a borrower (so it knows to add the borrower back if they enter a market in the future)
    }

    emit MarketExited(cToken, msg.sender);

    return uint256(Error.NO_ERROR);
  }

  /*** Policy Hooks ***/

  /**
   * @notice Checks if the account should be allowed to mint tokens in the given market
   * @param cToken The market to verify the mint against
   * @param minter The account which would get the minted tokens
   * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
   * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function mintAllowed(
    address cToken,
    address minter,
    uint256 mintAmount
  ) external override returns (uint256) {
    // Pausing is a very serious situation - we revert to sound the alarms
    require(!mintGuardianPaused[cToken], "!mint:paused");

    // Shh - currently unused
    minter;
    mintAmount;

    // Make sure market is listed
    if (!markets[cToken].isListed) {
      return uint256(Error.MARKET_NOT_LISTED);
    }

    // Make sure minter is whitelisted
    if (enforceWhitelist && !whitelist[minter]) {
      return uint256(Error.SUPPLIER_NOT_WHITELISTED);
    }

    // Check supply cap
    uint256 supplyCap = supplyCaps[cToken];
    // Supply cap of 0 corresponds to unlimited supplying
    if (supplyCap != 0) {
      uint256 totalCash = CTokenInterface(cToken).getCash();
      uint256 totalBorrows = CTokenInterface(cToken).totalBorrows();
      uint256 totalReserves = CTokenInterface(cToken).totalReserves();
      uint256 totalFuseFees = CTokenInterface(cToken).totalFuseFees();
      uint256 totalAdminFees = CTokenInterface(cToken).totalAdminFees();

      // totalUnderlyingSupply = totalCash + totalBorrows - (totalReserves + totalFuseFees + totalAdminFees)
      (MathError mathErr, uint256 totalUnderlyingSupply) = addThenSubUInt(
        totalCash,
        totalBorrows,
        add_(add_(totalReserves, totalFuseFees), totalAdminFees)
      );
      if (mathErr != MathError.NO_ERROR) return uint256(Error.MATH_ERROR);

      uint256 nextTotalUnderlyingSupply;
      (mathErr, nextTotalUnderlyingSupply) = addUInt(totalUnderlyingSupply, mintAmount);
      if (mathErr != MathError.NO_ERROR) return uint256(Error.MATH_ERROR);

      require(nextTotalUnderlyingSupply < supplyCap, "!supply cap");
    }

    // Keep the flywheel moving
    flywheelPreSupplierAction(cToken, minter);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Checks if the account should be allowed to redeem tokens in the given market
   * @param cToken The market to verify the redeem against
   * @param redeemer The account which would redeem the tokens
   * @param redeemTokens The number of cTokens to exchange for the underlying asset in the market
   * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function redeemAllowed(
    address cToken,
    address redeemer,
    uint256 redeemTokens
  ) external override returns (uint256) {
    uint256 allowed = redeemAllowedInternal(cToken, redeemer, redeemTokens);
    if (allowed != uint256(Error.NO_ERROR)) {
      return allowed;
    }

    // Keep the flywheel moving
    flywheelPreSupplierAction(cToken, redeemer);

    return uint256(Error.NO_ERROR);
  }

  function redeemAllowedInternal(
    address cToken,
    address redeemer,
    uint256 redeemTokens
  ) internal view returns (uint256) {
    if (!markets[cToken].isListed) {
      return uint256(Error.MARKET_NOT_LISTED);
    }

    /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
    if (!markets[cToken].accountMembership[redeemer]) {
      return uint256(Error.NO_ERROR);
    }

    /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
    (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
      redeemer,
      CTokenInterface(cToken),
      redeemTokens,
      0
    );
    if (err != Error.NO_ERROR) {
      return uint256(err);
    }
    if (shortfall > 0) {
      return uint256(Error.INSUFFICIENT_LIQUIDITY);
    }

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Validates redeem and reverts on rejection. May emit logs.
   * @param cToken Asset being redeemed
   * @param redeemer The address redeeming the tokens
   * @param redeemAmount The amount of the underlying asset being redeemed
   * @param redeemTokens The number of tokens being redeemed
   */
  function redeemVerify(
    address cToken,
    address redeemer,
    uint256 redeemAmount,
    uint256 redeemTokens
  ) external override {
    // Shh - currently unused
    cToken;
    redeemer;

    // Require tokens is zero or amount is also zero
    if (redeemTokens == 0 && redeemAmount > 0) {
      revert("!zero");
    }
  }

  function getMaxRedeemOrBorrow(
    address account,
    address cToken,
    bool isBorrow
  ) external override returns (uint256) {
    CTokenInterface cTokenModify = CTokenInterface(cToken);
    // Accrue interest
    uint256 balanceOfUnderlying = cTokenModify.asCTokenExtensionInterface().balanceOfUnderlying(account);

    // Get account liquidity
    (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
      account,
      isBorrow ? cTokenModify : CTokenInterface(address(0)),
      0,
      0
    );
    require(err == Error.NO_ERROR, "!liquidity");
    if (shortfall > 0) return 0; // Shortfall, so no more borrow/redeem

    // Get max borrow/redeem
    uint256 maxBorrowOrRedeemAmount;

    if (!isBorrow && !markets[cToken].accountMembership[account]) {
      // Max redeem = balance of underlying if not used as collateral
      maxBorrowOrRedeemAmount = balanceOfUnderlying;
    } else {
      // Avoid "stack too deep" error by separating this logic
      maxBorrowOrRedeemAmount = _getMaxRedeemOrBorrow(liquidity, cTokenModify, isBorrow);

      // Redeem only: max out at underlying balance
      if (!isBorrow && balanceOfUnderlying < maxBorrowOrRedeemAmount) maxBorrowOrRedeemAmount = balanceOfUnderlying;
    }

    // Get max borrow or redeem considering cToken liquidity
    uint256 cTokenLiquidity = cTokenModify.getCash();

    // Return the minimum of the two maximums
    return maxBorrowOrRedeemAmount <= cTokenLiquidity ? maxBorrowOrRedeemAmount : cTokenLiquidity;
  }

  /**
   * @dev Portion of the logic in `getMaxRedeemOrBorrow` above separated to avoid "stack too deep" errors.
   */
  function _getMaxRedeemOrBorrow(
    uint256 liquidity,
    CTokenInterface cTokenModify,
    bool isBorrow
  ) internal view returns (uint256) {
    if (liquidity == 0) return 0; // No available account liquidity, so no more borrow/redeem

    // Get the normalized price of the asset
    uint256 conversionFactor = oracle.getUnderlyingPrice(cTokenModify);
    require(conversionFactor > 0, "!oracle");

    // Pre-compute a conversion factor from tokens -> ether (normalized price value)
    if (!isBorrow) {
      uint256 collateralFactorMantissa = markets[address(cTokenModify)].collateralFactorMantissa;
      conversionFactor = (collateralFactorMantissa * conversionFactor) / 1e18;
    }

    // Get max borrow or redeem considering excess account liquidity
    return (liquidity * 1e18) / conversionFactor;
  }

  /**
   * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
   * @param cToken The market to verify the borrow against
   * @param borrower The account which would borrow the asset
   * @param borrowAmount The amount of underlying the account would borrow
   * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function borrowAllowed(
    address cToken,
    address borrower,
    uint256 borrowAmount
  ) external override returns (uint256) {
    // Pausing is a very serious situation - we revert to sound the alarms
    require(!borrowGuardianPaused[cToken], "!borrow:paused");

    // Make sure market is listed
    if (!markets[cToken].isListed) {
      return uint256(Error.MARKET_NOT_LISTED);
    }

    if (!markets[cToken].accountMembership[borrower]) {
      // only cTokens may call borrowAllowed if borrower not in market
      require(msg.sender == cToken, "!ctoken");

      // attempt to add borrower to the market
      Error err = addToMarketInternal(CTokenInterface(msg.sender), borrower);
      if (err != Error.NO_ERROR) {
        return uint256(err);
      }

      // it should be impossible to break the important invariant
      assert(markets[cToken].accountMembership[borrower]);
    }

    // Make sure oracle price is available
    if (oracle.getUnderlyingPrice(CTokenInterface(cToken)) == 0) {
      return uint256(Error.PRICE_ERROR);
    }

    // Make sure borrower is whitelisted
    if (enforceWhitelist && !whitelist[borrower]) {
      return uint256(Error.SUPPLIER_NOT_WHITELISTED);
    }

    // Check borrow cap
    uint256 borrowCap = borrowCaps[cToken];
    // Borrow cap of 0 corresponds to unlimited borrowing
    if (borrowCap != 0) {
      uint256 totalBorrows = CTokenInterface(cToken).totalBorrows();
      (MathError mathErr, uint256 nextTotalBorrows) = addUInt(totalBorrows, borrowAmount);
      if (mathErr != MathError.NO_ERROR) return uint256(Error.MATH_ERROR);
      require(nextTotalBorrows < borrowCap, "!borrow:cap");
    }

    // Keep the flywheel moving
    flywheelPreBorrowerAction(cToken, borrower);

    // Perform a hypothetical liquidity check to guard against shortfall
    (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
      borrower,
      CTokenInterface(cToken),
      0,
      borrowAmount
    );
    if (err != Error.NO_ERROR) {
      return uint256(err);
    }
    if (shortfall > 0) {
      return uint256(Error.INSUFFICIENT_LIQUIDITY);
    }

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
   * @param cToken Asset whose underlying is being borrowed
   * @param accountBorrowsNew The user's new borrow balance of the underlying asset
   */
  function borrowWithinLimits(address cToken, uint256 accountBorrowsNew) external view override returns (uint256) {
    // Check if min borrow exists
    uint256 minBorrowEth = IFuseFeeDistributor(fuseAdmin).minBorrowEth();

    if (minBorrowEth > 0) {
      // Get new underlying borrow balance of account for this cToken
      uint256 oraclePriceMantissa = oracle.getUnderlyingPrice(CTokenInterface(cToken));
      if (oraclePriceMantissa == 0) return uint256(Error.PRICE_ERROR);
      (MathError mathErr, uint256 borrowBalanceEth) = mulScalarTruncate(
        Exp({ mantissa: oraclePriceMantissa }),
        accountBorrowsNew
      );
      if (mathErr != MathError.NO_ERROR) return uint256(Error.MATH_ERROR);

      // Check against min borrow
      if (borrowBalanceEth < minBorrowEth) return uint256(Error.BORROW_BELOW_MIN);
    }

    // Return no error
    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Checks if the account should be allowed to repay a borrow in the given market
   * @param cToken The market to verify the repay against
   * @param payer The account which would repay the asset
   * @param borrower The account which would borrowed the asset
   * @param repayAmount The amount of the underlying asset the account would repay
   * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function repayBorrowAllowed(
    address cToken,
    address payer,
    address borrower,
    uint256 repayAmount
  ) external override returns (uint256) {
    // Shh - currently unused
    payer;
    borrower;
    repayAmount;

    // Make sure market is listed
    if (!markets[cToken].isListed) {
      return uint256(Error.MARKET_NOT_LISTED);
    }

    // Keep the flywheel moving
    flywheelPreBorrowerAction(cToken, borrower);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Checks if the liquidation should be allowed to occur
   * @param cTokenBorrowed Asset which was borrowed by the borrower
   * @param cTokenCollateral Asset which was used as collateral and will be seized
   * @param liquidator The address repaying the borrow and seizing the collateral
   * @param borrower The address of the borrower
   * @param repayAmount The amount of underlying being repaid
   */
  function liquidateBorrowAllowed(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) external override returns (uint256) {
    // Shh - currently unused
    liquidator;

    // Make sure markets are listed
    if (!markets[cTokenBorrowed].isListed || !markets[cTokenCollateral].isListed) {
      return uint256(Error.MARKET_NOT_LISTED);
    }

    // Get borrowers's underlying borrow balance
    uint256 borrowBalance = CTokenInterface(cTokenBorrowed).borrowBalanceStored(borrower);

    /* allow accounts to be liquidated if the market is deprecated */
    if (isDeprecated(CTokenInterface(cTokenBorrowed))) {
      require(borrowBalance >= repayAmount, "!borrow>repay");
    } else {
      /* The borrower must have shortfall in order to be liquidatable */
      (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
        borrower,
        CTokenInterface(address(0)),
        0,
        0
      );
      if (err != Error.NO_ERROR) {
        return uint256(err);
      }

      if (shortfall == 0) {
        return uint256(Error.INSUFFICIENT_SHORTFALL);
      }

      /* The liquidator may not repay more than what is allowed by the closeFactor */
      uint256 maxClose = mul_ScalarTruncate(Exp({ mantissa: closeFactorMantissa }), borrowBalance);
      if (repayAmount > maxClose) {
        return uint256(Error.TOO_MUCH_REPAY);
      }
    }

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Checks if the seizing of assets should be allowed to occur
   * @param cTokenCollateral Asset which was used as collateral and will be seized
   * @param cTokenBorrowed Asset which was borrowed by the borrower
   * @param liquidator The address repaying the borrow and seizing the collateral
   * @param borrower The address of the borrower
   * @param seizeTokens The number of collateral tokens to seize
   */
  function seizeAllowed(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external override returns (uint256) {
    // Pausing is a very serious situation - we revert to sound the alarms
    require(!seizeGuardianPaused, "!seize:paused");

    // Shh - currently unused
    liquidator;
    borrower;
    seizeTokens;

    // Make sure markets are listed
    if (!markets[cTokenCollateral].isListed || !markets[cTokenBorrowed].isListed) {
      return uint256(Error.MARKET_NOT_LISTED);
    }

    // Make sure cToken Comptrollers are identical
    if (CTokenInterface(cTokenCollateral).comptroller() != CTokenInterface(cTokenBorrowed).comptroller()) {
      return uint256(Error.COMPTROLLER_MISMATCH);
    }

    // Keep the flywheel moving
    flywheelPreTransferAction(cTokenCollateral, borrower, liquidator);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Checks if the account should be allowed to transfer tokens in the given market
   * @param cToken The market to verify the transfer against
   * @param src The account which sources the tokens
   * @param dst The account which receives the tokens
   * @param transferTokens The number of cTokens to transfer
   * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
   */
  function transferAllowed(
    address cToken,
    address src,
    address dst,
    uint256 transferTokens
  ) external override returns (uint256) {
    // Pausing is a very serious situation - we revert to sound the alarms
    require(!transferGuardianPaused, "!transfer:paused");

    // Currently the only consideration is whether or not
    //  the src is allowed to redeem this many tokens
    uint256 allowed = redeemAllowedInternal(cToken, src, transferTokens);
    if (allowed != uint256(Error.NO_ERROR)) {
      return allowed;
    }

    // Keep the flywheel moving
    flywheelPreTransferAction(cToken, src, dst);

    return uint256(Error.NO_ERROR);
  }

  /*** Flywheel Hooks ***/

  /**
   * @notice Keeps the flywheel moving pre-mint and pre-redeem
   * @param cToken The relevant market
   * @param supplier The minter/redeemer
   */
  function flywheelPreSupplierAction(address cToken, address supplier) internal {
    for (uint256 i = 0; i < rewardsDistributors.length; i++)
      IMidasFlywheel(rewardsDistributors[i]).flywheelPreSupplierAction(cToken, supplier);
  }

  /**
   * @notice Keeps the flywheel moving pre-borrow and pre-repay
   * @param cToken The relevant market
   * @param borrower The borrower
   */
  function flywheelPreBorrowerAction(address cToken, address borrower) internal {
    for (uint256 i = 0; i < rewardsDistributors.length; i++)
      IMidasFlywheel(rewardsDistributors[i]).flywheelPreBorrowerAction(cToken, borrower);
  }

  /**
   * @notice Keeps the flywheel moving pre-transfer and pre-seize
   * @param cToken The relevant market
   * @param src The account which sources the tokens
   * @param dst The account which receives the tokens
   */
  function flywheelPreTransferAction(
    address cToken,
    address src,
    address dst
  ) internal {
    for (uint256 i = 0; i < rewardsDistributors.length; i++)
      IMidasFlywheel(rewardsDistributors[i]).flywheelPreTransferAction(cToken, src, dst);
  }

  /*** Liquidity/Liquidation Calculations ***/

  /**
   * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
   *  Note that `cTokenBalance` is the number of cTokens the account owns in the market,
   *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
   */
  struct AccountLiquidityLocalVars {
    uint256 sumCollateral;
    uint256 sumBorrowPlusEffects;
    uint256 cTokenBalance;
    uint256 borrowBalance;
    uint256 exchangeRateMantissa;
    uint256 oraclePriceMantissa;
    Exp collateralFactor;
    Exp exchangeRate;
    Exp oraclePrice;
    Exp tokensToDenom;
    uint256 totalBorrowCapForCollateral;
    uint256 totalBorrowsBefore;
    uint256 borrowedAssetPrice;
  }

  function getAccountLiquidity(address account)
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
      account,
      CTokenInterface(address(0)),
      0,
      0
    );
    return (uint256(err), liquidity, shortfall);
  }

  /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
  function getHypotheticalAccountLiquidity(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  )
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
      account,
      CTokenInterface(cTokenModify),
      redeemTokens,
      borrowAmount
    );
    return (uint256(err), liquidity, shortfall);
  }

  /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param cTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral cToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
  function getHypotheticalAccountLiquidityInternal(
    address account,
    CTokenInterface cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount
  )
    internal
    view
    returns (
      Error,
      uint256,
      uint256
    )
  {
    AccountLiquidityLocalVars memory vars; // Holds all our calculation results
    uint256 oErr;

    if (address(cTokenModify) != address(0)) {
      vars.totalBorrowsBefore = cTokenModify.totalBorrows();
      vars.borrowedAssetPrice = oracle.getUnderlyingPrice(cTokenModify);
    }

    // For each asset the account is in
    CTokenInterface[] memory assets = accountAssets[account];
    for (uint256 i = 0; i < assets.length; i++) {
      CTokenInterface asset = assets[i];

      // Read the balances and exchange rate from the cToken
      (oErr, vars.cTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
      if (oErr != 0) {
        // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
        return (Error.SNAPSHOT_ERROR, 0, 0);
      }
      vars.collateralFactor = Exp({ mantissa: markets[address(asset)].collateralFactorMantissa });
      vars.exchangeRate = Exp({ mantissa: vars.exchangeRateMantissa });

      // Get the normalized price of the asset
      vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
      if (vars.oraclePriceMantissa == 0) {
        return (Error.PRICE_ERROR, 0, 0);
      }
      vars.oraclePrice = Exp({ mantissa: vars.oraclePriceMantissa });

      // Pre-compute a conversion factor from tokens -> ether (normalized price value)
      vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

      uint256 assetAsCollateralValueCap = type(uint256).max;
      // Exclude the asset-to-be-borrowed from the liquidity, except for when redeeming
      if (address(asset) != address(cTokenModify) || redeemTokens > 0) {
        // if the borrowed asset is capped against this collateral
        if (address(cTokenModify) != address(0)) {
          bool blacklisted = borrowingAgainstCollateralBlacklist[address(cTokenModify)][address(asset)];
          if (blacklisted) {
            assetAsCollateralValueCap = 0;
          } else {
            // the value of the collateral is capped regardless if any amount is to be borrowed
            vars.totalBorrowCapForCollateral = borrowCapForAssetForCollateral[address(cTokenModify)][address(asset)];
            // check if set to any value
            if (vars.totalBorrowCapForCollateral != 0) {
              // check for underflow
              if (vars.totalBorrowCapForCollateral >= vars.totalBorrowsBefore) {
                uint256 borrowAmountCap = vars.totalBorrowCapForCollateral - vars.totalBorrowsBefore;
                assetAsCollateralValueCap = (borrowAmountCap * vars.borrowedAssetPrice) / 1e18;
              } else {
                // should never happen, but better to not revert on this underflow
                assetAsCollateralValueCap = 0;
              }
            }
          }
        }

        // accumulate the collateral value to sumCollateral
        uint256 assetCollateralValue = mul_ScalarTruncate(vars.tokensToDenom, vars.cTokenBalance);
        if (assetCollateralValue > assetAsCollateralValueCap) assetCollateralValue = assetAsCollateralValueCap;
        vars.sumCollateral += assetCollateralValue;
      }

      // sumBorrowPlusEffects += oraclePrice * borrowBalance
      vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
        vars.oraclePrice,
        vars.borrowBalance,
        vars.sumBorrowPlusEffects
      );

      // Calculate effects of interacting with cTokenModify
      if (asset == cTokenModify) {
        // redeem effect
        // sumBorrowPlusEffects += tokensToDenom * redeemTokens
        vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
          vars.tokensToDenom,
          redeemTokens,
          vars.sumBorrowPlusEffects
        );

        // borrow effect
        // sumBorrowPlusEffects += oraclePrice * borrowAmount
        vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
          vars.oraclePrice,
          borrowAmount,
          vars.sumBorrowPlusEffects
        );
      }
    }

    // These are safe, as the underflow condition is checked first
    if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
      return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
    } else {
      return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
    }
  }

  /**
   * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
   * @dev Used in liquidation (called in cToken.liquidateBorrowFresh)
   * @param cTokenBorrowed The address of the borrowed cToken
   * @param cTokenCollateral The address of the collateral cToken
   * @param actualRepayAmount The amount of cTokenBorrowed underlying to convert into cTokenCollateral tokens
   * @return (errorCode, number of cTokenCollateral tokens to be seized in a liquidation)
   */
  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint256 actualRepayAmount
  ) external view override returns (uint256, uint256) {
    /* Read oracle prices for borrowed and collateral markets */
    uint256 priceBorrowedMantissa = oracle.getUnderlyingPrice(CTokenInterface(cTokenBorrowed));
    uint256 priceCollateralMantissa = oracle.getUnderlyingPrice(CTokenInterface(cTokenCollateral));
    if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
      return (uint256(Error.PRICE_ERROR), 0);
    }

    /*
     * Get the exchange rate and calculate the number of collateral tokens to seize:
     *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
     *  seizeTokens = seizeAmount / exchangeRate
     *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
     */
    CTokenInterface collateralCToken = CTokenInterface(cTokenCollateral);
    uint256 exchangeRateMantissa = collateralCToken.asCTokenExtensionInterface().exchangeRateStored(); // Note: reverts on error
    uint256 seizeTokens;
    Exp memory numerator;
    Exp memory denominator;
    Exp memory ratio;

    uint256 protocolSeizeShareMantissa = collateralCToken.protocolSeizeShareMantissa();
    uint256 feeSeizeShareMantissa = collateralCToken.feeSeizeShareMantissa();

    /*
     * The liquidation penalty includes
     * - the liquidator incentive
     * - the protocol fees (fuse admin fees)
     * - the market fee
     */
    Exp memory totalPenaltyMantissa = add_(
      add_(Exp({ mantissa: liquidationIncentiveMantissa }), Exp({ mantissa: protocolSeizeShareMantissa })),
      Exp({ mantissa: feeSeizeShareMantissa })
    );

    numerator = mul_(totalPenaltyMantissa, Exp({ mantissa: priceBorrowedMantissa }));
    denominator = mul_(Exp({ mantissa: priceCollateralMantissa }), Exp({ mantissa: exchangeRateMantissa }));
    ratio = div_(numerator, denominator);

    seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);
    return (uint256(Error.NO_ERROR), seizeTokens);
  }

  /*** Admin Functions ***/

  /**
   * @notice Add a RewardsDistributor contracts.
   * @dev Admin function to add a RewardsDistributor contract
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _addRewardsDistributor(address distributor) external returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.ADD_REWARDS_DISTRIBUTOR_OWNER_CHECK);
    }

    // Check marker method
    require(IMidasFlywheel(distributor).isRewardsDistributor(), "!isRewardsDistributor");

    // Check for existing RewardsDistributor
    for (uint256 i = 0; i < rewardsDistributors.length; i++) require(distributor != rewardsDistributors[i], "!added");

    // Add RewardsDistributor to array
    rewardsDistributors.push(distributor);
    emit AddedRewardsDistributor(distributor);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sets the whitelist enforcement for the comptroller
   * @dev Admin function to set a new whitelist enforcement boolean
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setWhitelistEnforcement(bool enforce) external returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_WHITELIST_ENFORCEMENT_OWNER_CHECK);
    }

    // Check if `enforceWhitelist` already equals `enforce`
    if (enforceWhitelist == enforce) {
      return uint256(Error.NO_ERROR);
    }

    // Set comptroller's `enforceWhitelist` to `enforce`
    enforceWhitelist = enforce;

    // Emit WhitelistEnforcementChanged(bool enforce);
    emit WhitelistEnforcementChanged(enforce);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sets the whitelist `statuses` for `suppliers`
   * @dev Admin function to set the whitelist `statuses` for `suppliers`
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setWhitelistStatuses(address[] calldata suppliers, bool[] calldata statuses) external returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_WHITELIST_STATUS_OWNER_CHECK);
    }

    // Set whitelist statuses for suppliers
    for (uint256 i = 0; i < suppliers.length; i++) {
      address supplier = suppliers[i];

      if (statuses[i]) {
        // If not already whitelisted, add to whitelist
        if (!whitelist[supplier]) {
          whitelist[supplier] = true;
          whitelistArray.push(supplier);
          whitelistIndexes[supplier] = whitelistArray.length - 1;
        }
      } else {
        // If whitelisted, remove from whitelist
        if (whitelist[supplier]) {
          whitelistArray[whitelistIndexes[supplier]] = whitelistArray[whitelistArray.length - 1]; // Copy last item in list to location of item to be removed
          whitelistArray.pop(); // Reduce length by 1
          whitelistIndexes[whitelistArray[whitelistIndexes[supplier]]] = whitelistIndexes[supplier]; // Set whitelist index of moved item to correct index
          whitelistIndexes[supplier] = 0; // Reset supplier whitelist index to 0 for a gas refund
          whitelist[supplier] = false; // Tell the contract that the supplier is no longer whitelisted
        }
      }
    }

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sets a new price oracle for the comptroller
   * @dev Admin function to set a new price oracle
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setPriceOracle(PriceOracle newOracle) public returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
    }

    // Track the old oracle for the comptroller
    PriceOracle oldOracle = oracle;

    // Set comptroller's oracle to newOracle
    oracle = newOracle;

    // Emit NewPriceOracle(oldOracle, newOracle)
    emit NewPriceOracle(oldOracle, newOracle);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sets the closeFactor used when liquidating borrows
   * @dev Admin function to set closeFactor
   * @param newCloseFactorMantissa New close factor, scaled by 1e18
   * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
   */
  function _setCloseFactor(uint256 newCloseFactorMantissa) external returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_CLOSE_FACTOR_OWNER_CHECK);
    }

    // Check limits
    Exp memory newCloseFactorExp = Exp({ mantissa: newCloseFactorMantissa });
    Exp memory lowLimit = Exp({ mantissa: closeFactorMinMantissa });
    if (lessThanOrEqualExp(newCloseFactorExp, lowLimit)) {
      return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
    }

    Exp memory highLimit = Exp({ mantissa: closeFactorMaxMantissa });
    if (lessThanExp(highLimit, newCloseFactorExp)) {
      return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
    }

    // Set pool close factor to new close factor, remember old value
    uint256 oldCloseFactorMantissa = closeFactorMantissa;
    closeFactorMantissa = newCloseFactorMantissa;

    // Emit event
    emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sets the collateralFactor for a market
   * @dev Admin function to set per-market collateralFactor
   * @param cToken The market to set the factor on
   * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
   * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
   */
  function _setCollateralFactor(CTokenInterface cToken, uint256 newCollateralFactorMantissa) public returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
    }

    // Verify market is listed
    Market storage market = markets[address(cToken)];
    if (!market.isListed) {
      return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
    }

    Exp memory newCollateralFactorExp = Exp({ mantissa: newCollateralFactorMantissa });

    // Check collateral factor <= 0.9
    Exp memory highLimit = Exp({ mantissa: collateralFactorMaxMantissa });
    if (lessThanExp(highLimit, newCollateralFactorExp)) {
      return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
    }

    // If collateral factor != 0, fail if price == 0
    if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(cToken) == 0) {
      return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
    }

    // Set market's collateral factor to new collateral factor, remember old value
    uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
    market.collateralFactorMantissa = newCollateralFactorMantissa;

    // Emit event with asset, old collateral factor, and new collateral factor
    emit NewCollateralFactor(cToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Sets liquidationIncentive
   * @dev Admin function to set liquidationIncentive
   * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
   * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
   */
  function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
    }

    // Check de-scaled min <= newLiquidationIncentive <= max
    Exp memory newLiquidationIncentive = Exp({ mantissa: newLiquidationIncentiveMantissa });
    Exp memory minLiquidationIncentive = Exp({ mantissa: liquidationIncentiveMinMantissa });
    if (lessThanExp(newLiquidationIncentive, minLiquidationIncentive)) {
      return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
    }

    Exp memory maxLiquidationIncentive = Exp({ mantissa: liquidationIncentiveMaxMantissa });
    if (lessThanExp(maxLiquidationIncentive, newLiquidationIncentive)) {
      return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
    }

    // Save current value for use in log
    uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

    // Set liquidation incentive to new incentive
    liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

    // Emit event with old incentive, new incentive
    emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Add the market to the markets mapping and set it as listed
   * @dev Admin function to set isListed and add support for the market
   * @param cToken The address of the market (token) to list
   * @return uint 0=success, otherwise a failure. (See enum Error for details)
   */
  function _supportMarket(CTokenInterface cToken) internal returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
    }

    // Is market already listed?
    if (markets[address(cToken)].isListed) {
      return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
    }
    // Sanity check to make sure its really a CToken
    require(cToken.isCToken(), "!market:isctoken");

    // Check cToken.comptroller == this
    require(address(cToken.comptroller()) == address(this), "!comptroller");

    // Make sure market is not already listed
    address underlying = CErc20Interface(address(cToken)).underlying();

    if (address(cTokensByUnderlying[underlying]) != address(0)) {
      return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
    }

    // List market and emit event
    Market storage market = markets[address(cToken)];
    market.isListed = true;
    market.collateralFactorMantissa = 0;
    allMarkets.push(cToken);
    cTokensByUnderlying[underlying] = cToken;
    emit MarketListed(cToken);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Deploy cToken, add the market to the markets mapping, and set it as listed and set the collateral factor
   * @dev Admin function to deploy cToken, set isListed, and add support for the market and set the collateral factor
   * @return uint 0=success, otherwise a failure. (See enum Error for details)
   */
  function _deployMarket(
    bool isCEther,
    bytes calldata constructorData,
    uint256 collateralFactorMantissa
  ) external returns (uint256) {
    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
    }

    // Temporarily enable Fuse admin rights for asset deployment (storing the original value)
    bool oldFuseAdminHasRights = fuseAdminHasRights;
    fuseAdminHasRights = true;

    // Deploy via Fuse admin
    CTokenInterface cToken = CTokenInterface(IFuseFeeDistributor(fuseAdmin).deployCErc20(constructorData));
    // Reset Fuse admin rights to the original value
    fuseAdminHasRights = oldFuseAdminHasRights;
    // Support market here in the Comptroller
    uint256 err = _supportMarket(cToken);

    // Set collateral factor
    return err == uint256(Error.NO_ERROR) ? _setCollateralFactor(cToken, collateralFactorMantissa) : err;
  }

  /**
   * @notice Toggles the auto-implementation feature
   * @param enabled If the feature is to be enabled
   * @return uint 0=success, otherwise a failure. (See enum Error for details)
   */
  function _toggleAutoImplementations(bool enabled) public returns (uint256) {
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.TOGGLE_AUTO_IMPLEMENTATIONS_ENABLED_OWNER_CHECK);
    }

    // Return no error if already set to the desired value
    if (autoImplementation == enabled) return uint256(Error.NO_ERROR);

    // Store autoImplementation with value enabled
    autoImplementation = enabled;

    // Emit AutoImplementationsToggled(enabled)
    emit AutoImplementationsToggled(enabled);

    return uint256(Error.NO_ERROR);
  }

  function _become(Unitroller unitroller) public {
    require(
      (msg.sender == address(fuseAdmin) && unitroller.fuseAdminHasRights()) ||
        (msg.sender == unitroller.admin() && unitroller.adminHasRights()),
      "!admin"
    );

    uint256 changeStatus = unitroller._acceptImplementation();
    require(changeStatus == 0, "!unauthorized - not pending impl");

    Comptroller(payable(address(unitroller)))._becomeImplementation();
  }

  function _becomeImplementation() external {
    require(msg.sender == comptrollerImplementation, "!implementation");

    address[] memory currentExtensions = LibDiamond.listExtensions();
    for (uint256 i = 0; i < currentExtensions.length; i++) {
      LibDiamond.removeExtension(DiamondExtension(currentExtensions[i]));
    }

    address[] memory latestExtensions = IFuseFeeDistributor(fuseAdmin).getComptrollerExtensions(
      comptrollerImplementation
    );
    for (uint256 i = 0; i < latestExtensions.length; i++) {
      LibDiamond.addExtension(DiamondExtension(latestExtensions[i]));
    }

    if (!_notEnteredInitialized) {
      _notEntered = true;
      _notEnteredInitialized = true;
    }
  }

  /**
   * @dev register a logic extension
   * @param extensionToAdd the extension whose functions are to be added
   * @param extensionToReplace the extension whose functions are to be removed/replaced
   */
  function _registerExtension(DiamondExtension extensionToAdd, DiamondExtension extensionToReplace) external override {
    require(msg.sender == address(fuseAdmin) && fuseAdminHasRights, "!unauthorized - no admin rights");
    LibDiamond.registerExtension(extensionToAdd, extensionToReplace);
  }

  /*** Helper Functions ***/

  /**
   * @notice Returns true if the given cToken market has been deprecated
   * @dev All borrows in a deprecated cToken market can be immediately liquidated
   * @param cToken The market to check if deprecated
   */
  function isDeprecated(CTokenInterface cToken) public view returns (bool) {
    return
      markets[address(cToken)].collateralFactorMantissa == 0 &&
      borrowGuardianPaused[address(cToken)] == true &&
      add_(add_(cToken.reserveFactorMantissa(), cToken.adminFeeMantissa()), cToken.fuseFeeMantissa()) == 1e18;
  }

  function asComptrollerFirstExtension() public view returns (ComptrollerFirstExtension) {
    return ComptrollerFirstExtension(address(this));
  }

  /*** Pool-Wide/Cross-Asset Reentrancy Prevention ***/

  /**
   * @dev Called by cTokens before a non-reentrant function for pool-wide reentrancy prevention.
   * Prevents pool-wide/cross-asset reentrancy exploits like AMP on Cream.
   */
  function _beforeNonReentrant() external override {
    require(markets[msg.sender].isListed, "!Comptroller:_beforeNonReentrant");
    require(_notEntered, "!reentered");
    _notEntered = false;
  }

  /**
   * @dev Called by cTokens after a non-reentrant function for pool-wide reentrancy prevention.
   * Prevents pool-wide/cross-asset reentrancy exploits like AMP on Cream.
   */
  function _afterNonReentrant() external override {
    require(markets[msg.sender].isListed, "!Comptroller:_afterNonReentrant");
    _notEntered = true; // get a gas-refund post-Istanbul
  }
}