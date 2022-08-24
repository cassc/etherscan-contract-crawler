// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveV3Polygon} from 'aave-address-book/AaveV3Polygon.sol';
import {IPoolConfigurator, ConfiguratorInputTypes} from 'aave-address-book/AaveV3.sol';
import {IERC20Metadata} from 'solidity-utils/contracts/oz-common/interfaces/IERC20Metadata.sol';
import {IProposalGenericExecutor} from '../../interfaces/IProposalGenericExecutor.sol';

/**
 * @author BGD Labs
 * @dev This payload lists MIMATIC (MAI) as borrowing asset and collateral (in isolation) on Aave V3 Polygon
 * - Parameter snapshot: https://snapshot.org/#/aave.eth/proposal/0x751b8fd1c77677643e419d327bdf749c29ccf0a0269e58ed2af0013843376051
 * The proposal is, as agreed with the proposer, more conservative than the approved parameters:
 * - Lowering the suggested 50M ceiling to a 2M ceiling
 * - The eMode lq treshold will be 97.5, instead of the suggested 98% as the parameters are per emode not per asset
 * - The reserve factor will be 10% instead of 5% to be consistent with other stable coins
 * - Adding a 100M supply cap.
 */
contract MiMaticPayload is IProposalGenericExecutor {
  // **************************
  // Protocol's contracts
  // **************************
  address public constant INCENTIVES_CONTROLLER =
    0x929EC64c34a17401F460460D4B9390518E5B473e;

  // **************************
  // New asset being listed (MIMATIC)
  // **************************

  address public constant UNDERLYING =
    0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;
  string public constant ATOKEN_NAME = 'Aave Polygon MIMATIC';
  string public constant ATOKEN_SYMBOL = 'aPolMIMATIC';
  string public constant VDTOKEN_NAME = 'Aave Polygon Variable Debt MIMATIC';
  string public constant VDTOKEN_SYMBOL = 'variableDebtPolMIMATIC';
  string public constant SDTOKEN_NAME = 'Aave Polygon Stable Debt MIMATIC';
  string public constant SDTOKEN_SYMBOL = 'stableDebtPolMIMATIC';

  address public constant PRICE_FEED =
    0xd8d483d813547CfB624b8Dc33a00F2fcbCd2D428;

  address public constant ATOKEN_IMPL =
    0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;
  address public constant VDTOKEN_IMPL =
    0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;
  address public constant SDTOKEN_IMPL =
    0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;
  address public constant RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  uint256 public constant RESERVE_FACTOR = 1000; // 10%

  uint256 public constant SUPPLY_CAP = 100_000_000; // 100m
  uint256 public constant LIQ_PROTOCOL_FEE = 1000; // 10%

  uint8 public constant EMODE_CATEGORY = 1; // Stablecoins

  // Params to set reserve as collateral (isolation)
  uint256 public constant LIQ_THRESHOLD = 8000; // 80%
  uint256 public constant LTV = 7500; // 75%
  uint256 public constant LIQ_BONUS = 10500; // 5%
  uint256 public constant DEBT_CEILING = 2_000_000_00; // 2m

  function execute() external override {
    // -------------
    // 0. Claim pool admin
    // Only needed for the first proposal on any market. If ACL_ADMIN was previously set it will ignore
    // https://github.com/aave/aave-v3-core/blob/master/contracts/dependencies/openzeppelin/contracts/AccessControl.sol#L207
    // -------------
    AaveV3Polygon.ACL_MANAGER.addPoolAdmin(AaveV3Polygon.ACL_ADMIN);

    // ----------------------------
    // 1. New price feed on oracle
    // ----------------------------
    address[] memory assets = new address[](1);
    assets[0] = UNDERLYING;
    address[] memory sources = new address[](1);
    sources[0] = PRICE_FEED;

    AaveV3Polygon.ORACLE.setAssetSources(assets, sources);

    // ------------------------------------------------
    // 2. Listing of MIMATIC, with all its configurations
    // ------------------------------------------------

    ConfiguratorInputTypes.InitReserveInput[]
      memory initReserveInputs = new ConfiguratorInputTypes.InitReserveInput[](
        1
      );
    initReserveInputs[0] = ConfiguratorInputTypes.InitReserveInput({
      aTokenImpl: ATOKEN_IMPL,
      stableDebtTokenImpl: SDTOKEN_IMPL,
      variableDebtTokenImpl: VDTOKEN_IMPL,
      underlyingAssetDecimals: IERC20Metadata(UNDERLYING).decimals(),
      interestRateStrategyAddress: RATE_STRATEGY,
      underlyingAsset: UNDERLYING,
      treasury: AaveV3Polygon.COLLECTOR,
      incentivesController: INCENTIVES_CONTROLLER,
      aTokenName: ATOKEN_NAME,
      aTokenSymbol: ATOKEN_SYMBOL,
      variableDebtTokenName: VDTOKEN_NAME,
      variableDebtTokenSymbol: VDTOKEN_SYMBOL,
      stableDebtTokenName: SDTOKEN_NAME,
      stableDebtTokenSymbol: SDTOKEN_SYMBOL,
      params: bytes('')
    });

    IPoolConfigurator configurator = AaveV3Polygon.POOL_CONFIGURATOR;

    configurator.initReserves(initReserveInputs);

    configurator.setSupplyCap(UNDERLYING, SUPPLY_CAP);

    configurator.setReserveBorrowing(UNDERLYING, true);

    configurator.setReserveFactor(UNDERLYING, RESERVE_FACTOR);

    configurator.setAssetEModeCategory(UNDERLYING, EMODE_CATEGORY);

    configurator.setLiquidationProtocolFee(UNDERLYING, LIQ_PROTOCOL_FEE);

    configurator.setDebtCeiling(UNDERLYING, DEBT_CEILING);

    configurator.configureReserveAsCollateral(
      UNDERLYING,
      LTV,
      LIQ_THRESHOLD,
      LIQ_BONUS
    );
  }
}