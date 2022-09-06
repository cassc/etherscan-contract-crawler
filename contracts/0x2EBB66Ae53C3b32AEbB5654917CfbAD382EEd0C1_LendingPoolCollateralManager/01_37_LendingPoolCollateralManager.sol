// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import {IERC20} from '../../dependencies/openzeppelin/contracts//IERC20.sol';
import {IVToken} from '../../interfaces/IVToken.sol';
import {INToken} from '../../interfaces/INToken.sol';
import {IERC721WithStat} from '../../interfaces/IERC721WithStat.sol';
//import {IStableDebtToken} from '../../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {IPriceOracleGetter} from '../../interfaces/IPriceOracleGetter.sol';
import {ILendingPoolCollateralManager} from '../../interfaces/ILendingPoolCollateralManager.sol';
import {INFTXEligibility} from '../../interfaces/INFTXEligibility.sol';
import {VersionedInitializable} from '../libraries/aave-upgradeability/VersionedInitializable.sol';
import {GenericLogic} from '../libraries/logic/GenericLogic.sol';
import {Helpers} from '../libraries/helpers/Helpers.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
//import {NFTVaultLogic} from '../libraries/logic/NFTVaultLogic.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {NFTVaultConfiguration} from '../libraries/configuration/NFTVaultConfiguration.sol';
import {UserConfiguration} from '../libraries/configuration/UserConfiguration.sol';
import {ValidationLogic} from '../libraries/logic/ValidationLogic.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {LendingPoolStorage} from './LendingPoolStorage.sol';

/**
 * @title LendingPoolCollateralManager contract
 * @author Aave
 * @dev Implements actions involving management of collateral in the protocol, the main one being the liquidations
 * IMPORTANT This contract will run always via DELEGATECALL, through the LendingPool, so the chain of inheritance
 * is the same as the LendingPool, to have compatible storage layouts
 **/
contract LendingPoolCollateralManager is
  ILendingPoolCollateralManager,
  VersionedInitializable,
  LendingPoolStorage
{
  using GPv2SafeERC20 for IERC20;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  //using NFTVaultLogic for DataTypes.NFTVaultData;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  uint256 internal constant LIQUIDATION_CLOSE_FACTOR_PERCENT = 5000;

  /**
   * @dev As thIS contract extends the VersionedInitializable contract to match the state
   * of the LendingPool contract, the getRevision() function is needed, but the value is not
   * important, as the initialize() function will never be called here
   */
  function getRevision() internal pure override returns (uint256) {
    return 0;
  }

  struct NFTLiquidationCallLocalVars {
    uint256[] maxCollateralAmountsToLiquidate;
    //uint256 userStableDebt;
    uint256 userVariableDebt;
    //uint256 userTotalDebt;
    uint256 maxLiquidatableDebt;
    uint256 actualDebtToLiquidate;
    uint256 liquidationRatio;
    //uint256 userStableRate;
    uint256 extraDebtAssetToPay;
    uint256 healthFactor;
    uint256 userCollateralBalance;
    uint256 totalCollateralToLiquidate;
    uint256 liquidatorPreviousNTokenBalance;
    INToken collateralNtoken;
    IERC721WithStat collateralTokenData;
    bool isCollateralEnabled;
    DataTypes.InterestRateMode borrowRateMode;
    uint256 errorCode;
    string errorMsg;
  }

  struct AvailableNFTCollateralToLiquidateParameters {
    address collateralAsset;
    address debtAsset;
    address user;
    uint256 debtToCover;
    uint256 userTotalDebt;
    uint256[] tokenIdsToLiquidate;
    uint256[] amountsToLiquidate;
  }

  function nftLiquidationCall(
    NFTLiquidationCallParameters calldata params
  ) external override returns (uint256, string memory) {
    DataTypes.NFTVaultData storage collateralVault = _nftVaults.data[params.collateralAsset];
    DataTypes.ReserveData storage debtReserve = _reserves.data[params.debtAsset];
    DataTypes.UserConfigurationMap storage userConfig = _usersConfig[params.user];

    NFTLiquidationCallLocalVars memory vars;

    (, , , , vars.healthFactor) = GenericLogic.calculateUserAccountData(
      params.user,
      _reserves,
      _nftVaults,
      userConfig,
      _addressesProvider.getPriceOracle()
    );

    (, vars.userVariableDebt) = Helpers.getUserCurrentDebt(params.user, debtReserve);

    (vars.errorCode, vars.errorMsg) = ValidationLogic.validateNFTLiquidationCall(
      collateralVault,
      debtReserve,
      userConfig,
      vars.healthFactor,
      0,//vars.userStableDebt,
      vars.userVariableDebt
    );

    if (Errors.CollateralManagerErrors(vars.errorCode) != Errors.CollateralManagerErrors.NO_ERROR) {
      return (vars.errorCode, vars.errorMsg);
    }

    vars.collateralNtoken = INToken(collateralVault.nTokenAddress);
    vars.collateralTokenData = IERC721WithStat(collateralVault.nTokenAddress);
    vars.userCollateralBalance = vars.collateralTokenData.balanceOf(params.user);

    vars.maxLiquidatableDebt = vars.userVariableDebt.percentMul(
      LIQUIDATION_CLOSE_FACTOR_PERCENT
    );

    vars.actualDebtToLiquidate = vars.maxLiquidatableDebt;
    {
      AvailableNFTCollateralToLiquidateParameters memory callparams;
      callparams.collateralAsset = params.collateralAsset;
      callparams.debtAsset = params.debtAsset;
      callparams.user = params.user;
      callparams.debtToCover = vars.actualDebtToLiquidate;
      callparams.userTotalDebt = vars.userVariableDebt;
      callparams.tokenIdsToLiquidate = params.tokenIds;
      callparams.amountsToLiquidate = params.amounts;
      (
        vars.maxCollateralAmountsToLiquidate,
        vars.totalCollateralToLiquidate,
        vars.actualDebtToLiquidate,
        vars.extraDebtAssetToPay
      ) = _calculateAvailableNFTCollateralToLiquidate(
        collateralVault,
        debtReserve,
        callparams
      );
      if(vars.actualDebtToLiquidate == 0){
        return(
          uint256(Errors.CollateralManagerErrors.NO_COLLATERAL_AVAILABLE),
          Errors.LCPM_NO_COLLATERAL_AVAILABLE);
      }
    }

    // If debtAmountNeeded < actualDebtToLiquidate, there isn't enough
    // collateral to cover the actual amount that is being liquidated, hence we liquidate
    // a smaller amount

    debtReserve.updateState();

    IVariableDebtToken(debtReserve.variableDebtTokenAddress).burn(
      params.user,
      vars.actualDebtToLiquidate,
      debtReserve.variableBorrowIndex
    );

    debtReserve.updateInterestRates(
      params.debtAsset,
      debtReserve.vTokenAddress,
      vars.actualDebtToLiquidate + vars.extraDebtAssetToPay,
      0
    );

    // If the collateral being liquidated is equal to the user balance,
    // we set the currency as not being used as collateral anymore
    if (vars.totalCollateralToLiquidate == vars.userCollateralBalance) {
      userConfig.setUsingNFTVaultAsCollateral(collateralVault.id, false);
      emit NFTVaultUsedAsCollateralDisabled(params.collateralAsset, params.user);
    }

    if (vars.actualDebtToLiquidate == vars.userVariableDebt) {
      userConfig.setBorrowing(debtReserve.id, false);
    }

    if (params.receiveNToken) {
      vars.liquidatorPreviousNTokenBalance = vars.collateralTokenData.balanceOf(msg.sender);
      vars.collateralNtoken.transferOnLiquidation(params.user, msg.sender, params.tokenIds, vars.maxCollateralAmountsToLiquidate);

      if (vars.liquidatorPreviousNTokenBalance == 0) {
        {
          DataTypes.UserConfigurationMap storage liquidatorConfig = _usersConfig[msg.sender];
          liquidatorConfig.setUsingNFTVaultAsCollateral(collateralVault.id, true);
        }
        emit NFTVaultUsedAsCollateralEnabled(params.collateralAsset, msg.sender);
      }
    } else {
      INFTXEligibility(collateralVault.nftEligibility).afterLiquidationHook(params.tokenIds, vars.maxCollateralAmountsToLiquidate);

      // Burn the equivalent amount of nToken, sending the underlying to the liquidator
      vars.collateralNtoken.burnBatch(
        params.user,
        msg.sender,
        params.tokenIds,
        vars.maxCollateralAmountsToLiquidate
      );
    }

    // Transfers the debt asset being repaid to the vToken, where the liquidity is kept
    IERC20(params.debtAsset).safeTransferFrom(
      msg.sender,
      debtReserve.vTokenAddress,
      vars.actualDebtToLiquidate + vars.extraDebtAssetToPay
    );

    if (vars.extraDebtAssetToPay != 0) {
      IVToken(debtReserve.vTokenAddress).mint(params.user, vars.extraDebtAssetToPay, debtReserve.liquidityIndex);
      emit Deposit(params.debtAsset, msg.sender, params.user, vars.extraDebtAssetToPay);
    }

    NFTLiquidationCallData memory data;
    data.debtToCover = vars.actualDebtToLiquidate;
    data.extraAssetToPay = vars.extraDebtAssetToPay;
    data.liquidatedCollateralTokenIds = params.tokenIds;
    data.liquidatedCollateralAmounts = vars.maxCollateralAmountsToLiquidate;
    data.liquidator = msg.sender;
    data.receiveNToken = params.receiveNToken;
    emit NFTLiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      abi.encode(data)
    );

    return (uint256(Errors.CollateralManagerErrors.NO_ERROR), Errors.LPCM_NO_ERRORS);
  }

  struct AvailableNFTCollateralToLiquidateLocalVars {
    uint256 userCompoundedBorrowBalance;
    uint256 liquidationBonus;
    uint256 collateralPrice;
    uint256 debtAssetPrice;
    uint256 valueOfDebtToLiquidate;
    uint256 valueOfAllDebt;
    uint256 valueOfCollateral;
    uint256 extraDebtAssetToPay;
    uint256 maxCollateralBalanceToLiquidate;
    uint256 totalCollateralBalanceToLiquidate;
    uint256[] collateralAmountsToLiquidate;
    uint256 debtAssetDecimals;
  }



  /**
   * @dev Calculates how much of a specific collateral can be liquidated, given
   * a certain amount of debt asset.
   * - This function needs to be called after all the checks to validate the liquidation have been performed,
   *   otherwise it might fail.
   * @param collateralVault The data of the collateral vault
   * @param debtReserve The data of the debt reserve
   * @return collateralAmounts: The maximum amount that is possible to liquidate given all the liquidation constraints
   *                           (user balance, close factor)
   *         debtAmountNeeded: The amount to repay with the liquidation
   **/
  function _calculateAvailableNFTCollateralToLiquidate(
    DataTypes.NFTVaultData storage collateralVault,
    DataTypes.ReserveData storage debtReserve,
    AvailableNFTCollateralToLiquidateParameters memory params
  ) internal view returns (uint256[] memory, uint256, uint256, uint256) {
    uint256 debtAmountNeeded = 0;
    IPriceOracleGetter oracle = IPriceOracleGetter(_addressesProvider.getPriceOracle());

    AvailableNFTCollateralToLiquidateLocalVars memory vars;
    vars.collateralAmountsToLiquidate = new uint256[](params.amountsToLiquidate.length);


    vars.collateralPrice = oracle.getAssetPrice(params.collateralAsset);
    vars.debtAssetPrice = oracle.getAssetPrice(params.debtAsset);

    (, , vars.liquidationBonus) = collateralVault
      .configuration
      .getParams();
    vars.debtAssetDecimals = debtReserve.configuration.getDecimals();

    // This is the maximum possible amount of the selected collateral that can be liquidated, given the
    // max amount of liquidatable debt
    vars.valueOfCollateral = vars.collateralPrice * (10**vars.debtAssetDecimals);
    vars.maxCollateralBalanceToLiquidate = ((vars.debtAssetPrice * params.debtToCover)
      .percentMul(vars.liquidationBonus)
      + vars.valueOfCollateral - 1)
      / vars.valueOfCollateral;
    (vars.totalCollateralBalanceToLiquidate, vars.collateralAmountsToLiquidate) = 
      INToken(collateralVault.nTokenAddress).getLiquidationAmounts(params.user, vars.maxCollateralBalanceToLiquidate, params.tokenIdsToLiquidate, params.amountsToLiquidate);

    debtAmountNeeded = (vars.valueOfCollateral
        * vars.totalCollateralBalanceToLiquidate
        / vars.debtAssetPrice)
        .percentDiv(vars.liquidationBonus);
    if (vars.totalCollateralBalanceToLiquidate < vars.maxCollateralBalanceToLiquidate) {
      vars.extraDebtAssetToPay = 0;
    } else if (debtAmountNeeded <= params.userTotalDebt){
      vars.extraDebtAssetToPay = 0;
    } else {
      vars.extraDebtAssetToPay = debtAmountNeeded - params.userTotalDebt;
      debtAmountNeeded = params.userTotalDebt;
    }
    return (vars.collateralAmountsToLiquidate, vars.totalCollateralBalanceToLiquidate, debtAmountNeeded, vars.extraDebtAssetToPay);
  }
}