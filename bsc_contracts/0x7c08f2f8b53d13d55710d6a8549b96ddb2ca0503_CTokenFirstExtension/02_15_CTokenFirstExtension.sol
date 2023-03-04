// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { DiamondExtension } from "../midas/DiamondExtension.sol";
import { CTokenBaseInterface, CTokenInterface } from "./CTokenInterfaces.sol";
import { ComptrollerV3Storage, UnitrollerAdminStorage } from "./ComptrollerStorage.sol";
import { TokenErrorReporter } from "./ErrorReporter.sol";
import { Exponential } from "./Exponential.sol";
import { CDelegationStorage } from "./CDelegateInterface.sol";
import { InterestRateModel } from "./InterestRateModel.sol";
import { IFuseFeeDistributor } from "./IFuseFeeDistributor.sol";
import { Multicall } from "../utils/Multicall.sol";

contract CTokenFirstExtension is
  CDelegationStorage,
  CTokenBaseInterface,
  TokenErrorReporter,
  Exponential,
  DiamondExtension,
  Multicall
{
  function _getExtensionFunctions() external view virtual override returns (bytes4[] memory) {
    uint8 fnsCount = 18;
    bytes4[] memory functionSelectors = new bytes4[](fnsCount);
    functionSelectors[--fnsCount] = this.transfer.selector;
    functionSelectors[--fnsCount] = this.transferFrom.selector;
    functionSelectors[--fnsCount] = this.allowance.selector;
    functionSelectors[--fnsCount] = this.approve.selector;
    functionSelectors[--fnsCount] = this.balanceOf.selector;
    functionSelectors[--fnsCount] = this._setAdminFee.selector;
    functionSelectors[--fnsCount] = this._setInterestRateModel.selector;
    functionSelectors[--fnsCount] = this._setNameAndSymbol.selector;
    functionSelectors[--fnsCount] = this._setReserveFactor.selector;
    functionSelectors[--fnsCount] = this.supplyRatePerBlock.selector;
    functionSelectors[--fnsCount] = this.borrowRatePerBlock.selector;
    functionSelectors[--fnsCount] = this.exchangeRateStored.selector;
    functionSelectors[--fnsCount] = this.exchangeRateCurrent.selector;
    functionSelectors[--fnsCount] = this.accrueInterest.selector;
    functionSelectors[--fnsCount] = this.totalBorrowsCurrent.selector;
    functionSelectors[--fnsCount] = this.balanceOfUnderlying.selector;
    functionSelectors[--fnsCount] = this.multicall.selector;
    functionSelectors[--fnsCount] = this.exchangeRateHypothetical.selector;

    require(fnsCount == 0, "use the correct array length");
    return functionSelectors;
  }

  /* ERC20 fns */
  /**
   * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
   * @dev Called by both `transfer` and `transferFrom` internally
   * @param spender The address of the account performing the transfer
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param tokens The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferTokens(
    address spender,
    address src,
    address dst,
    uint256 tokens
  ) internal returns (uint256) {
    /* Fail if transfer not allowed */
    uint256 allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
    if (allowed != 0) {
      return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.TRANSFER_COMPTROLLER_REJECTION, allowed);
    }

    /* Do not allow self-transfers */
    if (src == dst) {
      return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
    }

    /* Get the allowance, infinite for the account owner */
    uint256 startingAllowance = 0;
    if (spender == src) {
      startingAllowance = type(uint256).max;
    } else {
      startingAllowance = transferAllowances[src][spender];
    }

    /* Do the calculations, checking for {under,over}flow */
    MathError mathErr;
    uint256 allowanceNew;
    uint256 srcTokensNew;
    uint256 dstTokensNew;

    (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
    if (mathErr != MathError.NO_ERROR) {
      return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ALLOWED);
    }

    (mathErr, srcTokensNew) = subUInt(accountTokens[src], tokens);
    if (mathErr != MathError.NO_ERROR) {
      return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ENOUGH);
    }

    (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
    if (mathErr != MathError.NO_ERROR) {
      return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_TOO_MUCH);
    }

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)

    accountTokens[src] = srcTokensNew;
    accountTokens[dst] = dstTokensNew;

    /* Eat some of the allowance (if necessary) */
    if (startingAllowance != type(uint256).max) {
      transferAllowances[src][spender] = allowanceNew;
    }

    /* We emit a Transfer event */
    emit Transfer(src, dst, tokens);

    /* We call the defense hook */
    // unused function
    // comptroller.transferVerify(address(this), src, dst, tokens);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 amount) external nonReentrant(false) returns (bool) {
    return transferTokens(msg.sender, msg.sender, dst, amount) == uint256(Error.NO_ERROR);
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external nonReentrant(false) returns (bool) {
    return transferTokens(msg.sender, src, dst, amount) == uint256(Error.NO_ERROR);
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param amount The number of tokens that are approved (-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    address src = msg.sender;
    transferAllowances[src][spender] = amount;
    emit Approval(src, spender, amount);
    return true;
  }

  /**
   * @notice Get the current allowance from `owner` for `spender`
   * @param owner The address of the account which owns the tokens to be spent
   * @param spender The address of the account which may transfer tokens
   * @return The number of tokens allowed to be spent (-1 means infinite)
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return transferAllowances[owner][spender];
  }

  /**
   * @notice Get the token balance of the `owner`
   * @param owner The address of the account to query
   * @return The number of tokens owned by `owner`
   */
  function balanceOf(address owner) external view returns (uint256) {
    return accountTokens[owner];
  }

  /*** Admin Functions ***/

  /**
   * @notice updates the cToken ERC20 name and symbol
   * @dev Admin function to update the cToken ERC20 name and symbol
   * @param _name the new ERC20 token name to use
   * @param _symbol the new ERC20 token symbol to use
   */
  function _setNameAndSymbol(string calldata _name, string calldata _symbol) external {
    // Check caller is admin
    require(hasAdminRights(), "!admin");

    // Set ERC20 name and symbol
    name = _name;
    symbol = _symbol;
  }

  /**
   * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
   * @dev Admin function to accrue interest and set a new reserve factor
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setReserveFactor(uint256 newReserveFactorMantissa) external nonReentrant(false) returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reserve factor change failed.
      return fail(Error(error), FailureInfo.SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED);
    }

    // Check caller is admin
    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_RESERVE_FACTOR_ADMIN_CHECK);
    }

    // Verify market's block number equals current block number
    if (accrualBlockNumber != block.number) {
      return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_RESERVE_FACTOR_FRESH_CHECK);
    }

    // Check newReserveFactor ≤ maxReserveFactor
    if (newReserveFactorMantissa + adminFeeMantissa + fuseFeeMantissa > reserveFactorPlusFeesMaxMantissa) {
      return fail(Error.BAD_INPUT, FailureInfo.SET_RESERVE_FACTOR_BOUNDS_CHECK);
    }

    uint256 oldReserveFactorMantissa = reserveFactorMantissa;
    reserveFactorMantissa = newReserveFactorMantissa;

    emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice accrues interest and sets a new admin fee for the protocol using _setAdminFeeFresh
   * @dev Admin function to accrue interest and set a new admin fee
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setAdminFee(uint256 newAdminFeeMantissa) external nonReentrant(false) returns (uint256) {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted admin fee change failed.
      return fail(Error(error), FailureInfo.SET_ADMIN_FEE_ACCRUE_INTEREST_FAILED);
    }

    // Verify market's block number equals current block number
    if (accrualBlockNumber != block.number) {
      return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_ADMIN_FEE_FRESH_CHECK);
    }

    // Sanitize newAdminFeeMantissa
    if (newAdminFeeMantissa == type(uint256).max) newAdminFeeMantissa = adminFeeMantissa;

    // Get latest Fuse fee
    uint256 newFuseFeeMantissa = IFuseFeeDistributor(fuseAdmin).interestFeeRate();

    // Check reserveFactorMantissa + newAdminFeeMantissa + newFuseFeeMantissa ≤ reserveFactorPlusFeesMaxMantissa
    if (reserveFactorMantissa + newAdminFeeMantissa + newFuseFeeMantissa > reserveFactorPlusFeesMaxMantissa) {
      return fail(Error.BAD_INPUT, FailureInfo.SET_ADMIN_FEE_BOUNDS_CHECK);
    }

    // If setting admin fee
    if (adminFeeMantissa != newAdminFeeMantissa) {
      // Check caller is admin
      if (!hasAdminRights()) {
        return fail(Error.UNAUTHORIZED, FailureInfo.SET_ADMIN_FEE_ADMIN_CHECK);
      }

      // Set admin fee
      uint256 oldAdminFeeMantissa = adminFeeMantissa;
      adminFeeMantissa = newAdminFeeMantissa;

      // Emit event
      emit NewAdminFee(oldAdminFeeMantissa, newAdminFeeMantissa);
    }

    // If setting Fuse fee
    if (fuseFeeMantissa != newFuseFeeMantissa) {
      // Set Fuse fee
      uint256 oldFuseFeeMantissa = fuseFeeMantissa;
      fuseFeeMantissa = newFuseFeeMantissa;

      // Emit event
      emit NewFuseFee(oldFuseFeeMantissa, newFuseFeeMantissa);
    }

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
   * @dev Admin function to accrue interest and update the interest rate model
   * @param newInterestRateModel the new interest rate model to use
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function _setInterestRateModel(InterestRateModel newInterestRateModel)
    external
    nonReentrant(false)
    returns (uint256)
  {
    uint256 error = accrueInterest();
    if (error != uint256(Error.NO_ERROR)) {
      return fail(Error(error), FailureInfo.SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED);
    }

    if (!hasAdminRights()) {
      return fail(Error.UNAUTHORIZED, FailureInfo.SET_INTEREST_RATE_MODEL_OWNER_CHECK);
    }

    if (accrualBlockNumber != block.number) {
      return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_INTEREST_RATE_MODEL_FRESH_CHECK);
    }

    require(newInterestRateModel.isInterestRateModel(), "!notIrm");

    InterestRateModel oldInterestRateModel = interestRateModel;
    interestRateModel = newInterestRateModel;
    emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Returns the current per-block borrow interest rate for this cToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256) {
    return
      interestRateModel.getBorrowRate(
        asCToken().getCash(),
        totalBorrows,
        totalReserves + totalAdminFees + totalFuseFees
      );
  }

  /**
   * @notice Returns the current per-block supply interest rate for this cToken
   * @return The supply interest rate per block, scaled by 1e18
   */
  function supplyRatePerBlock() external view returns (uint256) {
    return
      interestRateModel.getSupplyRate(
        asCToken().getCash(),
        totalBorrows,
        totalReserves + totalAdminFees + totalFuseFees,
        reserveFactorMantissa + fuseFeeMantissa + adminFeeMantissa
      );
  }

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() public returns (uint256) {
    require(accrueInterest() == uint256(Error.NO_ERROR), "!accrueInterest");
    return exchangeRateStored();
  }

  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @dev This function does not accrue interest before calculating the exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() public view returns (uint256) {
    uint256 totalCash = asCToken().getCash();

    return
      _exchangeRateHypothetical(
        totalSupply,
        initialExchangeRateMantissa,
        totalCash,
        totalBorrows,
        totalReserves,
        totalAdminFees,
        totalFuseFees
      );
  }

  function exchangeRateHypothetical() public view returns (uint256) {
    uint256 cashPrior = asCToken().getCash();
    if (block.number == accrualBlockNumber) {
      return exchangeRateStored();
    } else {
      InterestAccrual memory accrual = accrueInterestHypothetical(block.number, cashPrior);

      return
        _exchangeRateHypothetical(
          accrual.totalSupply,
          initialExchangeRateMantissa,
          accrual.totalCash,
          accrual.totalBorrows,
          accrual.totalReserves,
          accrual.totalAdminFees,
          accrual.totalFuseFees
        );
    }
  }

  function _exchangeRateHypothetical(
    uint256 _totalSupply,
    uint256 _initialExchangeRateMantissa,
    uint256 _totalCash,
    uint256 _totalBorrows,
    uint256 _totalReserves,
    uint256 _totalAdminFees,
    uint256 _totalFuseFees
  ) internal pure returns (uint256) {
    if (_totalSupply == 0) {
      /*
       * If there are no tokens minted:
       *  exchangeRate = initialExchangeRate
       */
      return _initialExchangeRateMantissa;
    } else {
      /*
       * Otherwise:
       *  exchangeRate = (totalCash + totalBorrows - (totalReserves + totalFuseFees + totalAdminFees)) / totalSupply
       */
      uint256 cashPlusBorrowsMinusReserves;
      Exp memory exchangeRate;
      MathError mathErr;

      (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(
        _totalCash,
        _totalBorrows,
        _totalReserves + _totalAdminFees + _totalFuseFees
      );
      require(mathErr == MathError.NO_ERROR, "!addThenSubUInt overflow check failed");

      (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
      require(mathErr == MathError.NO_ERROR, "!getExp overflow check failed");

      return exchangeRate.mantissa;
    }
  }

  struct InterestAccrual {
    uint256 accrualBlockNumber;
    uint256 borrowIndex;
    uint256 totalSupply;
    uint256 totalCash;
    uint256 totalBorrows;
    uint256 totalReserves;
    uint256 totalFuseFees;
    uint256 totalAdminFees;
    uint256 interestAccumulated;
  }

  function accrueInterestHypothetical(uint256 blockNumber, uint256 cashPrior)
    internal
    view
    returns (InterestAccrual memory accrual)
  {
    uint256 totalFees = totalAdminFees + totalFuseFees;
    uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, totalBorrows, totalReserves + totalFees);
    if (borrowRateMantissa > borrowRateMaxMantissa) {
      if (cashPrior > totalFees) revert("!borrowRate");
      else borrowRateMantissa = borrowRateMaxMantissa;
    }
    (MathError mathErr, uint256 blockDelta) = subUInt(blockNumber, accrualBlockNumber);
    require(mathErr == MathError.NO_ERROR, "!blockDelta");

    /*
     * Calculate the interest accumulated into borrows and reserves and the new index:
     *  simpleInterestFactor = borrowRate * blockDelta
     *  interestAccumulated = simpleInterestFactor * totalBorrows
     *  totalBorrowsNew = interestAccumulated + totalBorrows
     *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
     *  totalFuseFeesNew = interestAccumulated * fuseFee + totalFuseFees
     *  totalAdminFeesNew = interestAccumulated * adminFee + totalAdminFees
     *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
     */

    accrual.accrualBlockNumber = blockNumber;
    accrual.totalSupply = totalSupply;
    Exp memory simpleInterestFactor = mul_(Exp({ mantissa: borrowRateMantissa }), blockDelta);
    accrual.interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, totalBorrows);
    accrual.totalBorrows = accrual.interestAccumulated + totalBorrows;
    accrual.totalReserves = mul_ScalarTruncateAddUInt(
      Exp({ mantissa: reserveFactorMantissa }),
      accrual.interestAccumulated,
      totalReserves
    );
    accrual.totalFuseFees = mul_ScalarTruncateAddUInt(
      Exp({ mantissa: fuseFeeMantissa }),
      accrual.interestAccumulated,
      totalFuseFees
    );
    accrual.totalAdminFees = mul_ScalarTruncateAddUInt(
      Exp({ mantissa: adminFeeMantissa }),
      accrual.interestAccumulated,
      totalAdminFees
    );
    accrual.borrowIndex = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndex, borrowIndex);
  }

  /**
   * @notice Applies accrued interest to total borrows and reserves
   * @dev This calculates interest accrued from the last checkpointed block
   *   up to the current block and writes new checkpoint to storage.
   */
  function accrueInterest() public virtual returns (uint256) {
    /* Remember the initial block number */
    uint256 currentBlockNumber = block.number;

    /* Short-circuit accumulating 0 interest */
    if (accrualBlockNumber == currentBlockNumber) {
      return uint256(Error.NO_ERROR);
    }

    uint256 cashPrior = asCToken().getCash();
    InterestAccrual memory accrual = accrueInterestHypothetical(currentBlockNumber, cashPrior);

    /////////////////////////
    // EFFECTS & INTERACTIONS
    // (No safe failures beyond this point)
    accrualBlockNumber = currentBlockNumber;
    borrowIndex = accrual.borrowIndex;
    totalBorrows = accrual.totalBorrows;
    totalReserves = accrual.totalReserves;
    totalFuseFees = accrual.totalFuseFees;
    totalAdminFees = accrual.totalAdminFees;
    emit AccrueInterest(cashPrior, accrual.interestAccumulated, borrowIndex, totalBorrows);
    return uint256(Error.NO_ERROR);
  }

  /**
   * @notice Returns the current total borrows plus accrued interest
   * @return The total borrows with interest
   */
  function totalBorrowsCurrent() external returns (uint256) {
    require(accrueInterest() == uint256(Error.NO_ERROR), "!accrueInterest");
    return totalBorrows;
  }

  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner) public returns (uint256) {
    require(accrueInterest() == uint256(Error.NO_ERROR), "!accrueInterest");
    Exp memory exchangeRate = Exp({ mantissa: exchangeRateStored() });
    (MathError mErr, uint256 balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
    require(mErr == MathError.NO_ERROR, "!balance");
    return balance;
  }

  /**
   * @notice Returns a boolean indicating if the sender has admin rights
   */
  function hasAdminRights() internal view returns (bool) {
    ComptrollerV3Storage comptrollerStorage = ComptrollerV3Storage(address(comptroller));
    return
      (msg.sender == comptrollerStorage.admin() && comptrollerStorage.adminHasRights()) ||
      (msg.sender == address(fuseAdmin) && comptrollerStorage.fuseAdminHasRights());
  }

  /*** Reentrancy Guard ***/

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   */
  modifier nonReentrant(bool localOnly) {
    _beforeNonReentrant(localOnly);
    _;
    _afterNonReentrant(localOnly);
  }

  /**
   * @dev Split off from `nonReentrant` to keep contract below the 24 KB size limit.
   * Saves space because function modifier code is "inlined" into every function with the modifier).
   * In this specific case, the optimization saves around 1500 bytes of that valuable 24 KB limit.
   */
  function _beforeNonReentrant(bool localOnly) private {
    require(_notEntered, "re-entered");
    if (!localOnly) comptroller._beforeNonReentrant();
    _notEntered = false;
  }

  /**
   * @dev Split off from `nonReentrant` to keep contract below the 24 KB size limit.
   * Saves space because function modifier code is "inlined" into every function with the modifier).
   * In this specific case, the optimization saves around 150 bytes of that valuable 24 KB limit.
   */
  function _afterNonReentrant(bool localOnly) private {
    _notEntered = true; // get a gas-refund post-Istanbul
    if (!localOnly) comptroller._afterNonReentrant();
  }

  function asCToken() internal view returns (CTokenInterface) {
    return CTokenInterface(address(this));
  }
}