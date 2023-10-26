//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "@aave/core-v3/contracts/interfaces/IAaveOracle.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

import { ReserveConfiguration } from "@aave/core-v3/contracts/protocol/libraries/configuration/ReserveConfiguration.sol";
import { ReserveLogic } from "@aave/core-v3/contracts/protocol/libraries/logic/ReserveLogic.sol";
import { ValidationLogic } from "@aave/core-v3/contracts/protocol/libraries/logic/ValidationLogic.sol";

import "../interfaces/IMoneyMarketView.sol";
import "../interfaces/IUnderlyingPositionFactory.sol";

contract AaveMoneyMarketView is IMoneyMarketView {

    using Math for *;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveLogic for DataTypes.ReserveCache;

    MoneyMarketId public immutable override moneyMarketId;
    IUnderlyingPositionFactory public immutable positionFactory;
    IPoolAddressesProvider public immutable provider;
    IPool public immutable pool;

    constructor(MoneyMarketId _moneyMarketId, IPoolAddressesProvider _provider, IUnderlyingPositionFactory _positionFactory) {
        moneyMarketId = _moneyMarketId;
        provider = _provider;
        pool = IPool(_provider.getPool());
        positionFactory = _positionFactory;
    }

    // ====== IMoneyMarketView =======

    function balances(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset)
        public
        view
        virtual
        override
        returns (Balances memory balances_)
    {
        balances_.collateral = IERC20(pool.getReserveData(address(collateralAsset)).aTokenAddress).balanceOf(_account(positionId));
        balances_.debt = IERC20(pool.getReserveData(address(debtAsset)).variableDebtTokenAddress).balanceOf(_account(positionId));
    }

    function normalisedBalances(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset)
        external
        view
        virtual
        override
        returns (NormalisedBalances memory balances_)
    {
        Prices memory _prices = prices(positionId.getSymbol(), collateralAsset, debtAsset);
        Balances memory _balances = balances(positionId, collateralAsset, debtAsset);

        balances_.collateral = _balances.collateral * _prices.collateral / 10 ** collateralAsset.decimals();
        balances_.debt = _balances.debt * _prices.debt / 10 ** debtAsset.decimals();
        balances_.unit = _prices.unit;
    }

    function prices(Symbol, IERC20 collateralAsset, IERC20 debtAsset) public view virtual override returns (Prices memory prices_) {
        address[] memory assets = new address[](2);
        assets[0] = address(collateralAsset);
        assets[1] = address(debtAsset);

        IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
        uint256[] memory pricesArr = oracle.getAssetsPrices(assets);

        prices_.collateral = pricesArr[0];
        prices_.debt = pricesArr[1];
        prices_.unit = oracle.BASE_CURRENCY_UNIT();
    }

    function borrowingLiquidity(IERC20 asset) public view virtual override returns (uint256 borrowingLiquidity_) {
        (DataTypes.ReserveData memory reserve, DataTypes.ReserveCache memory reserveCache) = _reserveAndCache(asset);

        uint256 totalDebt = ValidationLogic.totalDebt(reserveCache);
        uint256 borrowCap = reserve.configuration.getBorrowCap() * 10 ** reserve.configuration.getDecimals();
        uint256 maxBorrowable = borrowCap > totalDebt ? borrowCap - totalDebt : 0;
        uint256 assetBalance = asset.balanceOf(reserve.aTokenAddress);

        borrowingLiquidity_ = borrowCap == 0 ? assetBalance : Math.min(maxBorrowable, assetBalance);
    }

    function lendingLiquidity(IERC20 asset) public view virtual override returns (uint256 lendingLiquidity_) {
        (DataTypes.ReserveData memory reserve, DataTypes.ReserveCache memory reserveCache) = _reserveAndCache(asset);

        uint256 supplyCap = reserve.configuration.getSupplyCap() * 10 ** reserve.configuration.getDecimals();
        uint256 currentSupply = ValidationLogic.currentSupply(reserveCache, reserve);

        lendingLiquidity_ = supplyCap == 0 ? type(uint256).max : supplyCap > currentSupply ? supplyCap - currentSupply : 0;
    }

    function minCR(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset) external view virtual override returns (uint256) {
        (uint256 ltv,) = thresholds(positionId, collateralAsset, debtAsset);
        return 1e36 / ltv;
    }

    function thresholds(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset)
        public
        view
        virtual
        override
        returns (uint256 ltv, uint256 liquidationThreshold)
    {
        uint256 eModeCategory =
            positionId.getNumber() > 0 ? pool.getUserEMode(_account(positionId)) : _eModeCategory(collateralAsset, debtAsset);

        if (eModeCategory > 0) {
            DataTypes.EModeCategory memory eModeCategoryData = pool.getEModeCategoryData(uint8(eModeCategory));
            ltv = eModeCategoryData.ltv;
            liquidationThreshold = eModeCategoryData.liquidationThreshold;
        } else {
            DataTypes.ReserveConfigurationMap memory configuration = pool.getReserveData(address(collateralAsset)).configuration;
            ltv = configuration.getLtv();
            liquidationThreshold = configuration.getLiquidationThreshold();
        }

        ltv *= 1e14;
        liquidationThreshold *= 1e14;
    }

    function borrowingRate(IERC20 asset) external view virtual override returns (uint256 borrowingRate_) {
        borrowingRate_ = pool.getReserveData(address(asset)).currentVariableBorrowRate / 1e9;
    }

    function lendingRate(IERC20 asset) external view virtual override returns (uint256 lendingRate_) {
        lendingRate_ = pool.getReserveData(address(asset)).currentLiquidityRate / 1e9;
    }

    // ===== Internal Helper Functions =====

    function _reserveAndCache(IERC20 asset)
        internal
        view
        returns (DataTypes.ReserveData memory reserve, DataTypes.ReserveCache memory reserveCache)
    {
        reserve = pool.getReserveData(address(asset));
        reserveCache = reserve.cache();
        reserve.updateState(reserveCache);
    }

    function _eModeCategory(IERC20 collateralAsset, IERC20 debtAsset) internal view returns (uint256 eModeCategory) {
        uint256 collateralEModeCategory = pool.getReserveData(address(collateralAsset)).configuration.getEModeCategory();
        if (
            collateralEModeCategory > 0
                && collateralEModeCategory == pool.getReserveData(address(debtAsset)).configuration.getEModeCategory()
        ) eModeCategory = collateralEModeCategory;
    }

    function _account(PositionId positionId) internal view returns (address) {
        return address(positionFactory.moneyMarket(positionId));
    }

}