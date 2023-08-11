// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { DataTypes } from "../../earn-protocol-configuration/contracts/libraries/types/DataTypes.sol";
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import { IAdapterBorrow } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterBorrow.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";
import { IAdapterHarvestReward } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterHarvestReward.sol";
import { IAdapterStaking } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterStaking.sol";
import { IAdapterStakingCurve } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterStakingCurve.sol";
import { IAdapterFull } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterFull.sol";
import { IWETH } from "@optyfi/defi-legos/interfaces/misc/contracts/IWETH.sol";
import { IYWETH } from "@optyfi/defi-legos/interfaces/misc/contracts/IYWETH.sol";
import { IAaveV1PriceOracle } from "@optyfi/defi-legos/ethereum/aave/contracts/IAaveV1PriceOracle.sol";
import {
    IAaveV1LendingPoolAddressesProvider
} from "@optyfi/defi-legos/ethereum/aave/contracts/IAaveV1LendingPoolAddressesProvider.sol";
import {
    IAaveV1,
    UserReserveData,
    ReserveConfigurationData,
    ReserveDataV1,
    UserAccountData
} from "@optyfi/defi-legos/ethereum/aave/contracts/IAaveV1.sol";
import { IAaveV1Token } from "@optyfi/defi-legos/ethereum/aave/contracts/IAaveV1Token.sol";
import { IAaveV1LendingPoolCore } from "@optyfi/defi-legos/ethereum/aave/contracts/IAaveV1LendingPoolCore.sol";
import { IAaveV2PriceOracle } from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2PriceOracle.sol";
import {
    IAaveV2LendingPoolAddressesProvider
} from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2LendingPoolAddressesProvider.sol";
import {
    IAaveV2LendingPoolAddressProviderRegistry
} from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2LendingPoolAddressProviderRegistry.sol";
import { IAaveV2, ReserveDataV2 } from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2.sol";
import { IAaveV2Token } from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2Token.sol";
import {
    IAaveV2ProtocolDataProvider,
    ReserveDataProtocol
} from "@optyfi/defi-legos/ethereum/aavev2/contracts/IAaveV2ProtocolDataProvider.sol";
import { ICompound } from "@optyfi/defi-legos/ethereum/compound/contracts/ICompound.sol";
import { IETHGateway } from "@optyfi/defi-legos/interfaces/misc/contracts/IETHGateway.sol";
import { ICream } from "@optyfi/defi-legos/ethereum/cream/contracts/ICream.sol";
import { ICurveDeposit } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveDeposit.sol";
import { ICurveGauge } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveGauge.sol";
import {
    ICurveAddressProvider
} from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveAddressProvider.sol";
import { ICurveSwap } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveSwap.sol";
import { ICurveRegistry } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveRegistry.sol";
import { ITokenMinter } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ITokenMinter.sol";
import { IDForceDeposit } from "@optyfi/defi-legos/ethereum/dforce/contracts/IDForceDeposit.sol";
import { IDForceStake } from "@optyfi/defi-legos/ethereum/dforce/contracts/IDForceStake.sol";
import {
    IdYdX,
    AccountInfo,
    AssetAmount,
    AssetDenomination,
    AssetReference,
    ActionArgs,
    AssetReference,
    ActionType
} from "@optyfi/defi-legos/ethereum/dydx/contracts/IdYdX.sol";
import { IFulcrum } from "@optyfi/defi-legos/ethereum/fulcrum/contracts/IFulcrum.sol";
import { IHarvestController } from "@optyfi/defi-legos/ethereum/harvest.finance/contracts/IHarvestController.sol";
import { IHarvestDeposit } from "@optyfi/defi-legos/ethereum/harvest.finance/contracts/IHarvestDeposit.sol";
import { IHarvestFarm } from "@optyfi/defi-legos/ethereum/harvest.finance/contracts/IHarvestFarm.sol";
import { ISushiswapMasterChef } from "@optyfi/defi-legos/ethereum/sushiswap/contracts/ISushiswapMasterChef.sol";
import { IYearn } from "@optyfi/defi-legos/ethereum/yearn/contracts/IYearn.sol";
import { IYVault } from "@optyfi/defi-legos/ethereum/yvault/contracts/IYVault.sol";

contract Imports {
    /* solhint-disable no-empty-blocks */
    constructor() public {}
    /* solhint-disable no-empty-blocks */
}