// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {NFTVaultLogic} from './NFTVaultLogic.sol';
import {GenericLogic} from './GenericLogic.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {NFTVaultConfiguration} from '../configuration/NFTVaultConfiguration.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {Helpers} from '../helpers/Helpers.sol';
import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';
import {INFTXEligibility} from '../../../interfaces/INFTXEligibility.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 4000;
  uint256 public constant REBALANCE_UP_USAGE_RATIO_THRESHOLD = 0.95 * 1e27; //usage ratio of 95%

  /**
   * @dev Validates a deposit action
   * @param reserve The reserve object on which the user is depositing
   * @param amount The amount to be deposited
   */
  function validateDeposit(DataTypes.ReserveData storage reserve, uint256 amount) external view {
    (bool isActive, bool isFrozen, , ) = reserve.configuration.getFlags();

    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!isFrozen, Errors.VL_RESERVE_FROZEN);
  }

  function validateDepositNFT(DataTypes.NFTVaultData storage vault, uint256[] memory ids, uint256[] memory amounts) external view {
    (bool isActive, bool isFrozen) = vault.configuration.getFlags();

    require(ids.length != 0, Errors.VL_INVALID_AMOUNT);
    for(uint256 i = 0; i < ids.length; ++i) {
      require(amounts[i] != 0, Errors.VL_INVALID_AMOUNT);
    }
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!isFrozen, Errors.VL_RESERVE_FROZEN);
    INFTXEligibility eligibility = INFTXEligibility(vault.nftEligibility);
    require(eligibility.checkAllEligible(ids), Errors.VL_NFT_INELIGIBLE_TOKEN_ID);
  }

  function validateLockNFT(DataTypes.NFTVaultData storage vault, uint40 now) external view {
    require(vault.expiration >= now, Errors.VL_NFT_LOCK_ACTION_IS_EXPIRED);
  }

  /**
   * @dev Validates a withdraw action
   * @param reserveAddress The address of the reserve
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   * @param reserves The reserves state
   * @param userConfig The user configuration
   * @param oracle The price oracle
   */
  function validateWithdraw(
    address reserveAddress,
    uint256 amount,
    uint256 userBalance,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.UserConfigurationMap storage userConfig,
    address oracle
  ) external view {
    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(amount <= userBalance, Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);

    (bool isActive, , , ) = reserves.data[reserveAddress].configuration.getFlags();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
  }

  /**
   * @dev Validates a withdraw action
   * @param vaultAddress The address of the vault
   * @param tokenIds The array of token ids of the NFTs to be withdrawn
   * @param amounts The array of amounts of the NFTs to be withdrawn
   * @param userBalances The array of balances of every NFT in `tokenIds` of the user
   * @param reserves The reserves state
   * @param nftVaults The vaults state
   * @param userConfig The user configuration
   * @param oracle The price oracle
   */
  function validateWithdrawNFT(
    address vaultAddress,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    uint256[] calldata userBalances,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.PoolNFTVaultsData storage nftVaults,
    DataTypes.UserConfigurationMap storage userConfig,
    address oracle
  ) external view {
    require(tokenIds.length == amounts.length, Errors.VL_INVALID_AMOUNT);
    uint256 amount;
    for(uint256 i = 0; i < tokenIds.length; ++i) {
      require(amounts[i] != 0, Errors.VL_INVALID_AMOUNT);
      require(amounts[i] <= userBalances[i], Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);
      amount = amount + amounts[i];
    }

    (bool isActive, ) = nftVaults.data[vaultAddress].configuration.getFlags();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

    require(
      GenericLogic.balanceDecreaseAllowed(
        vaultAddress,
        msg.sender,
        amount,
        reserves,
        nftVaults,
        userConfig,
        oracle
      ),
      Errors.VL_TRANSFER_NOT_ALLOWED
    );
  }


  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 currentLiquidationThreshold;
    uint256 amountOfCollateralNeededETH;
    uint256 userCollateralBalanceETH;
    uint256 userBorrowBalanceETH;
    uint256 availableLiquidity;
    uint256 healthFactor;
    bool isActive;
    bool isFrozen;
    bool borrowingEnabled;
    //bool stableRateBorrowingEnabled;
  }

  /**
   * @dev Validates a borrow action
   * @param asset The address of the asset to borrow
   * @param reserve The reserve state from which the user is borrowing
   * @param userAddress The address of the user
   * @param amount The amount to be borrowed
   * @param amountInETH The amount to be borrowed, in ETH
   * @param interestRateMode The interest rate mode at which the user is borrowing
   * @param maxStableLoanPercent The max amount of the liquidity that can be borrowed at stable rate, in percentage
   * @param reserves The reserves state
   * @param nftVaults The vaults state
   * @param userConfig The user configuration
   * @param oracle The price oracle
   */
  function validateBorrow(
    address asset,
    DataTypes.ReserveData storage reserve,
    address userAddress,
    uint256 amount,
    uint256 amountInETH,
    uint256 interestRateMode,
    uint256 maxStableLoanPercent,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.PoolNFTVaultsData storage nftVaults,
    DataTypes.UserConfigurationMap storage userConfig,
    address oracle
  ) external view {
    ValidateBorrowLocalVars memory vars;

    (vars.isActive, vars.isFrozen, vars.borrowingEnabled, ) = reserve
      .configuration
      .getFlags();

    require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!vars.isFrozen, Errors.VL_RESERVE_FROZEN);
    require(amount != 0, Errors.VL_INVALID_AMOUNT);

    require(vars.borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);

    //validate interest rate mode
    require(
      uint256(DataTypes.InterestRateMode.VARIABLE) == interestRateMode,
      Errors.VL_INVALID_INTEREST_RATE_MODE_SELECTED
    );

    (
      vars.userCollateralBalanceETH,
      vars.userBorrowBalanceETH,
      vars.currentLtv,
      vars.currentLiquidationThreshold,
      vars.healthFactor
    ) = GenericLogic.calculateUserAccountData(
      userAddress,
      reserves,
      nftVaults,
      userConfig,
      oracle
    );

    require(vars.userCollateralBalanceETH > 0, Errors.VL_COLLATERAL_BALANCE_IS_0);

    require(
      vars.healthFactor > GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    vars.amountOfCollateralNeededETH = (vars.userBorrowBalanceETH + amountInETH).percentDiv(
      vars.currentLtv
    ); //LTV is calculated in percentage

    require(
      vars.amountOfCollateralNeededETH <= vars.userCollateralBalanceETH,
      Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW
    );

  }

  /**
   * @dev Validates a repay action
   * @param reserve The reserve state from which the user is repaying
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param onBehalfOf The address of the user msg.sender is repaying for
   * @param stableDebt The borrow balance of the user
   * @param variableDebt The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveData storage reserve,
    uint256 amountSent,
    DataTypes.InterestRateMode rateMode,
    address onBehalfOf,
    uint256 stableDebt,
    uint256 variableDebt
  ) external view {
    bool isActive = reserve.configuration.getActive();

    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

    require(amountSent > 0, Errors.VL_INVALID_AMOUNT);

    require(
        (variableDebt > 0 &&
          DataTypes.InterestRateMode(rateMode) == DataTypes.InterestRateMode.VARIABLE),
      Errors.VL_NO_DEBT_OF_SELECTED_TYPE
    );

    require(
      amountSent != type(uint256).max || msg.sender == onBehalfOf,
      Errors.VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
    );
  }

    /**
   * @dev Validates a nft-flashloan action
   * @param asset The asset being flashborrowed
   * @param tokenIds The tokenIds for each NFT being borrowed
   * @param amounts The amounts for each NFT being borrowed
   * @param userBalances The amounts for each NFT in the vault
   **/
  function validateNFTFlashloan(address asset, uint256[] memory tokenIds, uint256[] memory amounts, uint256[] memory userBalances) internal pure {
    require(tokenIds.length == amounts.length, Errors.VL_INCONSISTENT_FLASHLOAN_PARAMS);
    for(uint256 i = 0; i < tokenIds.length; ++i) {
      require(amounts[i] != 0, Errors.VL_INVALID_AMOUNT);
      require(amounts[i] <= userBalances[i], Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);
    }
  }

  /**
   * @dev Validates the liquidation action
   * @param collateralVault The vault data of the collateral
   * @param principalReserve The reserve data of the principal
   * @param userConfig The user configuration
   * @param userHealthFactor The user's health factor
   * @param userStableDebt Total stable debt balance of the user
   * @param userVariableDebt Total variable debt balance of the user
   **/
  function validateNFTLiquidationCall(
    DataTypes.NFTVaultData storage collateralVault,
    DataTypes.ReserveData storage principalReserve,
    DataTypes.UserConfigurationMap storage userConfig,
    uint256 userHealthFactor,
    uint256 userStableDebt,
    uint256 userVariableDebt
  ) internal view returns (uint256, string memory) {
    if (
      !collateralVault.configuration.getActive() || !principalReserve.configuration.getActive()
    ) {
      return (
        uint256(Errors.CollateralManagerErrors.NO_ACTIVE_RESERVE),
        Errors.VL_NO_ACTIVE_RESERVE
      );
    }

    if (userHealthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD) {
      return (
        uint256(Errors.CollateralManagerErrors.HEALTH_FACTOR_ABOVE_THRESHOLD),
        Errors.LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
      );
    }

    bool isCollateralEnabled =
      collateralVault.configuration.getLiquidationThreshold() > 0 &&
        userConfig.isUsingNFTVaultAsCollateral(collateralVault.id);

    //if collateral isn't enabled as collateral by user, it cannot be liquidated
    if (!isCollateralEnabled) {
      return (
        uint256(Errors.CollateralManagerErrors.COLLATERAL_CANNOT_BE_LIQUIDATED),
        Errors.LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED
      );
    }

    if (userVariableDebt == 0) {
      return (
        uint256(Errors.CollateralManagerErrors.CURRRENCY_NOT_BORROWED),
        Errors.LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
      );
    }

    return (uint256(Errors.CollateralManagerErrors.NO_ERROR), Errors.LPCM_NO_ERRORS);
  }

  /**
   * @dev Validates a vToken transfer or an nToken transfer
   * @param from The user from which the vTokens/nTokens are being transferred
   * @param reserves The state of all the reserves
   * @param nftVaults The state of all the NFT vaults
   * @param userConfig The state of the user for the specific reserve
   * @param oracle The price oracle
   */
  function validateTransfer(
    address from,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.PoolNFTVaultsData storage nftVaults,
    DataTypes.UserConfigurationMap storage userConfig,
    address oracle
  ) internal view {
    (, , , , uint256 healthFactor) =
      GenericLogic.calculateUserAccountData(
        from,
        reserves,
        nftVaults,
        userConfig,
        oracle
      );

    require(
      healthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_TRANSFER_NOT_ALLOWED
    );
  }
}