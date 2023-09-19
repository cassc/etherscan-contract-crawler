// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./PMMPricing.sol";
import "./Errors.sol";
import "./Types.sol";
import {ID3Oracle} from "contracts/intf/ID3Oracle.sol";

library PMMRangeOrder {
    uint256 internal constant ONE = 10 ** 18;

    // use fromToken bid curve and toToken ask curve
    function querySellTokens(
        Types.RangeOrderState memory roState,
        address fromToken,
        address toToken,
        uint256 fromTokenAmount
    ) internal view returns (uint256 fromAmount, uint256 receiveToToken, uint256 vusdAmount) {
        // contruct fromToken state and swap to vUSD
        uint256 receiveVUSD;
        {
            PMMPricing.PMMState memory fromTokenState = _contructTokenState(roState, true, false);
            receiveVUSD = PMMPricing._querySellQuoteToken(fromTokenState, fromTokenAmount);

            receiveVUSD = receiveVUSD > fromTokenState.BLeft ? fromTokenState.BLeft : receiveVUSD;
        }

        // construct toToken state and swap from vUSD to toToken
        {
            PMMPricing.PMMState memory toTokenState = _contructTokenState(roState, false, true);
            receiveToToken = PMMPricing._querySellQuoteToken(toTokenState, receiveVUSD);

            receiveToToken = receiveToToken > toTokenState.BLeft ? toTokenState.BLeft : receiveToToken;
        }

        // oracle protect
        {
            uint256 oracleToAmount = ID3Oracle(roState.oracle).getMaxReceive(fromToken, toToken, fromTokenAmount);
            require(oracleToAmount >= receiveToToken, Errors.RO_ORACLE_PROTECTION);
        }
        return (fromTokenAmount, receiveToToken, receiveVUSD);
    }

    // use fromToken bid curve and toToken ask curve
    function queryBuyTokens(
        Types.RangeOrderState memory roState,
        address fromToken,
        address toToken,
        uint256 toTokenAmount
    ) internal view returns (uint256 payFromToken, uint256 toAmount, uint256 vusdAmount) {
        // contruct fromToken to vUSD
        uint256 payVUSD;
        {
            PMMPricing.PMMState memory toTokenState = _contructTokenState(roState, false, true);
            require(
                toTokenAmount <= toTokenState.BMaxAmount - roState.toTokenMMInfo.cumulativeAsk, Errors.RO_VAULT_RESERVE
            );
            payVUSD = PMMPricing._queryBuyBaseToken(toTokenState, toTokenAmount);
        }

        // construct vUSD to toToken
        {
            PMMPricing.PMMState memory fromTokenState = _contructTokenState(roState, true, false);
            payFromToken = PMMPricing._queryBuyBaseToken(fromTokenState, payVUSD);
        }

        // oracle protect
        {
            uint256 oracleToAmount = ID3Oracle(roState.oracle).getMaxReceive(fromToken, toToken, payFromToken);
            require(oracleToAmount >= toTokenAmount, Errors.RO_ORACLE_PROTECTION);
        }

        return (payFromToken, toTokenAmount, payVUSD);
    }

    // ========= internal ==========
    function _contructTokenState(
        Types.RangeOrderState memory roState,
        bool fromTokenOrNot,
        bool askOrNot
    ) internal pure returns (PMMPricing.PMMState memory tokenState) {
        Types.TokenMMInfo memory tokenMMInfo = fromTokenOrNot ? roState.fromTokenMMInfo : roState.toTokenMMInfo;

        // bMax,k
        tokenState.BMaxAmount = askOrNot ? tokenMMInfo.askAmount : tokenMMInfo.bidAmount;

        // amount = 0 protection
        require(tokenState.BMaxAmount > 0, Errors.RO_AMOUNT_ZERO);
        tokenState.K = askOrNot ? tokenMMInfo.kAsk : tokenMMInfo.kBid;

        // i, B0
        uint256 upPrice;
        (tokenState.i, upPrice) = askOrNot
            ? (tokenMMInfo.askDownPrice, tokenMMInfo.askUpPrice)
            : (tokenMMInfo.bidDownPrice, tokenMMInfo.bidUpPrice);
        // price = 0 protection
        require(tokenState.i > 0, Errors.RO_PRICE_ZERO);
        tokenState.B0 = _calB0WithPriceLimit(upPrice, tokenState.K, tokenState.i, tokenState.BMaxAmount);
        // B
        tokenState.B = askOrNot ? tokenState.B0 - tokenMMInfo.cumulativeAsk : tokenState.B0 - tokenMMInfo.cumulativeBid;

        // BLeft
        tokenState.BLeft = askOrNot
            ? tokenState.BMaxAmount - tokenMMInfo.cumulativeAsk
            : tokenState.BMaxAmount - tokenMMInfo.cumulativeBid;

        return tokenState;
    }

    // P_up = i(1 - k + k*(B0 / B0 - amount)^2), record amount = A
    // (P_up + i*k - i) / i*k = (B0 / (B0 - A))^2
    // B0 = A + A / (sqrt((P_up + i*k - i) / i*k) - 1)
    // i = priceDown
    function _calB0WithPriceLimit(
        uint256 priceUp,
        uint256 k,
        uint256 i,
        uint256 amount
    ) internal pure returns (uint256 baseTarget) {
        // (P_up + i*k - i)
        // temp1 = PriceUp + DecimalMath.mul(i, k) - i
        // temp1 price

        // i*k
        // temp2 = DecimalMath.mul(i, k)
        // temp2 price

        // (P_up + i*k - i)/i*k
        // temp3 = DecimalMath(temp1, temp2)
        // temp3 ONE

        // temp4 = sqrt(temp3 * ONE)
        // temp4 ONE

        // temp5 = temp4 - ONE
        // temp5 ONE

        // B0 = amount + DecimalMath.div(amount, temp5)
        // B0 amount
        if (k == 0) {
            baseTarget = amount;
        } else {
            uint256 temp1 = priceUp * ONE + i * k - i * ONE;
            uint256 temp2 = i * k;
            uint256 temp3 = DecimalMath.div(temp1, temp2);
            uint256 temp5 = DecimalMath.sqrt(temp3) - ONE;
            require(temp5 > 0, Errors.RO_PRICE_DIFF_TOO_SMALL);
            baseTarget = amount + DecimalMath.div(amount, temp5);
        }
    }
}