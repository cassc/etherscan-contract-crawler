pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./Common.sol";
import "../lib/SafeMath.sol";
import "../interface/IPortfoliosCallable.sol";

import "./Liquidation.sol";
import "../storage/EscrowStorage.sol";

contract MockLiquidation is EscrowStorage {

    function setParameters(
        uint128 liquidityHaircut,
        uint128 liquidationDiscount,
        uint128 settlementDiscount,
        uint128 repoIncentive
    ) external {
        EscrowStorageSlot._setLiquidityHaircut(liquidityHaircut);
        EscrowStorageSlot._setLiquidationDiscount(liquidationDiscount);
        EscrowStorageSlot._setSettlementDiscount(settlementDiscount);
        EscrowStorageSlot._setLiquidityTokenRepoIncentive(repoIncentive);
    }

    event TradeCollateralCurrency(
        uint128 netLocalCurrencyPayer,
        int256 netLocalCurrencyLiquidator,
        uint128 collateralTransfer,
        int256 payerCollateralBalance
    );

    function liquidateCollateralCurrency(
        address payer,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        Liquidation.TransferAmounts memory transfer,
        Common.FreeCollateralFactors memory fc,
        Liquidation.RateParameters memory rateParam,
        address Portfolios
    ) public {
        Liquidation._liquidateCollateralCurrency(payer, localCurrencyRequired, liquidityHaircut, transfer, fc, rateParam, Portfolios);

        emit TradeCollateralCurrency(
            transfer.netLocalCurrencyPayer,
            transfer.netLocalCurrencyLiquidator,
            transfer.collateralTransfer,
            transfer.payerCollateralBalance
        );
    }

    function tradeCollateralCurrency(
        address payer,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        uint128 discountFactor,
        Liquidation.TransferAmounts memory transfer,
        Common.FreeCollateralFactors memory fc,
        Liquidation.RateParameters memory rateParam,
        address Portfolios
    ) public returns (uint128, uint128, int256) {
        Liquidation._tradeCollateralCurrency(payer, localCurrencyRequired, liquidityHaircut, discountFactor, transfer, fc, rateParam, Portfolios);

        emit TradeCollateralCurrency(
            transfer.netLocalCurrencyPayer,
            transfer.netLocalCurrencyLiquidator,
            transfer.collateralTransfer,
            transfer.payerCollateralBalance
        );
    }

    event LiquidityTokenTrade(uint128 cashClaimWithdrawn, uint128 localCurrencyRaised);
    function localLiquidityTokenTrade(
        address payer,
        uint16 localCurrency,
        uint128 localCurrencyRequired,
        uint128 liquidityHaircut,
        IPortfoliosCallable Portfolios
    ) public {
        (uint128 cashClaimWithdrawn, uint128 localCurrencyRaised) = 
            Liquidation._localLiquidityTokenTrade(
                payer,
                localCurrency,
                localCurrencyRequired,
                liquidityHaircut,
                IPortfoliosCallable(Portfolios)
            );

        emit LiquidityTokenTrade(cashClaimWithdrawn, localCurrencyRaised);
    }

    function calculatePostTradeFactors(
        uint128 cashClaimWithdrawn,
        int256 netCurrencyAvailable,
        uint128 localCurrencyRequired,
        uint128 localCurrencyRaised,
        uint128 liquidityHaircut
    ) public pure returns (int256, uint128, int256, uint128) {
        return Liquidation._calculatePostTradeFactors(cashClaimWithdrawn, netCurrencyAvailable, localCurrencyRequired, localCurrencyRaised, liquidityHaircut);
    }

    function calculateLocalCurrencyToTrade(
        uint128 localCurrencyRequired,
        uint128 liquidationDiscount,
        uint128 localCurrencyBuffer,
        uint128 maxLocalCurrencyDebt
    ) public pure returns (uint128) {
        return Liquidation._calculateLocalCurrencyToTrade(localCurrencyRequired, liquidationDiscount, localCurrencyBuffer, maxLocalCurrencyDebt);
    }

    function calculateLiquidityTokenHaircut(
        int256 postHaircutCashClaim,
        uint128 liquidityHaircut
    ) public pure returns (uint128)  {
        return Liquidation._calculateLiquidityTokenHaircut(postHaircutCashClaim, liquidityHaircut);
    }

    function calculateCollateralToSell(
        uint128 discountFactor,
        uint128 localCurrencyRequired,
        Liquidation.RateParameters memory rateParam
    ) public pure returns (uint128) {
        return Liquidation._calculateCollateralToSell(discountFactor, localCurrencyRequired, rateParam);
    }

    function calculateCollateralBalances(
        address payer,
        int256 payerBalance,
        uint16 collateralCurrency,
        uint128 collateralToSell,
        uint128 amountToRaise,
        address Portfolios
    ) public returns (int256) {
        return Liquidation._calculateCollateralBalances(payer, payerBalance, collateralCurrency, collateralToSell, amountToRaise, IPortfoliosCallable(Portfolios));
    }
}

contract MockPortfolios {
    using SafeMath for uint256;
    uint128 public _remainder;
    uint128 public _amount;
    uint128 public liquidityHaircut;
    uint128 public _cash;
    uint128 public _fCash;
    bool public _wasCalled;

    function setHaircut(uint128 haircut) public {
        liquidityHaircut = haircut;
    }

    function setRemainder(uint128 remainder) public {
        _remainder = remainder;
    }

    function setClaim(uint128 cash, uint128 fCash) public {
        _cash = cash;
        _fCash = fCash;
    }

    function getClaim() public view returns (uint128, uint128) {
        uint256 cashClaim = uint256(_cash)
            .mul(liquidityHaircut)
            .div(Common.DECIMALS);

        uint256 fCashClaim = uint256(_fCash)
            .mul(liquidityHaircut)
            .div(Common.DECIMALS);

        return (uint128(cashClaim), uint128(fCashClaim));
    }

    function raiseCurrentCashViaLiquidityToken(
        address /* account */,
        uint16 /* currency */,
        uint128 amount
    ) external returns (uint128) {
        _wasCalled = true;
        _amount = amount;

        // If cash is set we return the remainder here
        if (_cash != 0) {
            if (amount >= _cash) {
                return amount - _cash;
            } else {
                return 0;
            }
        }

        return _remainder;
    }
}