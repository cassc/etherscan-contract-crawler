// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseLendingStrategy} from "contracts/strategies/lending/BaseLendingStrategy.sol";
import {BaseFlashloanStrategy} from "contracts/strategies/flashloan/BaseFlashloanStrategy.sol";
import {ApyFlowVault, ERC20} from "contracts/ApyFlowVault.sol";
import {IERC4626Minimal} from "contracts/interfaces/IERC4626Minimal.sol";
import {IAssetConverter, SafeAssetConverter} from "contracts/libraries/SafeAssetConverter.sol";
import {PricesLibrary, ChainlinkPriceFeedAggregator} from "contracts/libraries/PricesLibrary.sol";

/// @author YLDR <[email protected]>
abstract contract BaseHedgedStrategyWrapper is ApyFlowVault, BaseLendingStrategy, BaseFlashloanStrategy {
    using SafeAssetConverter for IAssetConverter;
    using PricesLibrary for ChainlinkPriceFeedAggregator;

    IERC4626Minimal public immutable strategy;
    uint256 public immutable initialLTV;

    ChainlinkPriceFeedAggregator public immutable pricesOracle;
    IAssetConverter public immutable assetConverter;

    constructor(
        IERC4626Minimal _strategy,
        uint256 _initialLTV,
        ChainlinkPriceFeedAggregator _pricesOracle,
        IAssetConverter _assetConverter
    ) {
        strategy = _strategy;
        initialLTV = _initialLTV;

        pricesOracle = _pricesOracle;
        assetConverter = _assetConverter;

        require(asset() == address(collateral), "Invalid configuration");
        require(strategy.asset() == address(tokenToBorrow), "Invalid configuration");
    }

    function _totalAssets() internal view override returns (uint256 assets) {
        uint256 amountInUSD;
        BaseLendingStrategy.LendingPositionState memory lending = getLendingPositionState();
        amountInUSD += pricesOracle.convertToUSD(address(collateral), lending.collateral);
        amountInUSD += pricesOracle.convertToUSD(
            address(tokenToBorrow), strategy.convertToAssets(strategy.balanceOf(address(this)))
        );
        amountInUSD -= pricesOracle.convertToUSD(address(tokenToBorrow), lending.debt);

        assets = pricesOracle.convertFromUSD(amountInUSD, asset());
    }

    function _deposit(uint256 assets) internal override {
        uint256 ltv = _getCurrentLTV();
        uint256 amountToBorrow = _getNeededDebt(assets, ltv);
        _supply(assets);
        _borrow(amountToBorrow);
        strategy.deposit(amountToBorrow, address(this));
    }

    function _redeem(uint256 shares) internal override returns (uint256 assets) {
        uint256 amountToRedeem = strategy.balanceOf(address(this)) * shares / totalSupply();
        uint256 debtToRepay = _getCurrentDebt() * shares / totalSupply();

        uint256 borrowTokenReceived = strategy.redeem(amountToRedeem, address(this), address(this));

        if (borrowTokenReceived >= debtToRepay) {
            assets = _repayAndWithdrawProportionally(debtToRepay);
            assets += assetConverter.safeSwap(address(tokenToBorrow), asset(), borrowTokenReceived - debtToRepay);
        } else {
            // Capture collateral and debt before
            uint256 collateralBefore = _getCurrentCollateral();
            uint256 debtBefore = _getCurrentDebt();

            // Repay with funds withdrawn from strategy
            _repay(borrowTokenReceived);
            // Repay rest via flashloaned funds
            _takeFlashloan(
                asset(), pricesOracle.convert(address(tokenToBorrow), asset(), debtToRepay - borrowTokenReceived), ""
            );

            // Capture collateral and debt after
            uint256 collateralAfter = _getCurrentCollateral();
            uint256 debtAfter = _getCurrentDebt();

            // We want to decrease collateral and debt proportionally
            uint256 targetCollateralAfter = debtAfter * collateralBefore / debtBefore;

            uint256 amountToWithdraw = collateralAfter - targetCollateralAfter;
            assets = amountToWithdraw;
            _withdraw(amountToWithdraw);
        }
    }

    function _insideFlashloan(address, uint256 _amount, uint256 _amountOwed, bytes memory) internal override {
        uint256 amountToRepay = assetConverter.safeSwap(asset(), address(tokenToBorrow), _amount);

        _repay(amountToRepay);
        _withdraw(_amountOwed);
    }
}