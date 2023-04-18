// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IVault.sol";
import "../interfaces/ITrading.sol";
import "../interfaces/ITradingCore.sol";
import {ZERO, ONE, UC, uc, into} from "unchecked-counter/src/UC.sol";

library LibTrading {

    bytes32 constant TRADING_POSITION = keccak256("apollox.trading.storage");

    struct TradingStorage {
        uint256 salt;
        //--------------- pending ---------------
        // tradeHash =>
        mapping(bytes32 => ITrading.PendingTrade) pendingTrades;
        // margin.tokenIn => total amount of all pending trades
        mapping(address => uint256) pendingTradeAmountIns;
        //--------------- open ---------------
        // tradeHash =>
        mapping(bytes32 => ITrading.OpenTrade) openTrades;
        // user => tradeHash[]
        mapping(address => bytes32[]) userOpenTradeHashes;
        // tokenIn =>
        mapping(address => uint256) openTradeAmountIns;
        // tokenIn[]
        address[] openTradeTokenIns;
    }

    function tradingStorage() internal pure returns (TradingStorage storage ts) {
        bytes32 position = TRADING_POSITION;
        assembly {
            ts.slot := position
        }
    }

    function calcFundingFee(
        ITrading.OpenTrade memory ot,
        IVault.MarginToken memory mt,
        uint256 marketPrice
    ) internal view returns (int256 fundingFee) {
        int256 longAccFundingFeePerShare = ITradingCore(address(this)).lastLongAccFundingFeePerShare(ot.pairBase);
        return calcFundingFee(ot, mt, marketPrice, longAccFundingFeePerShare);
    }

    function calcFundingFee(
        ITrading.OpenTrade memory ot,
        IVault.MarginToken memory mt,
        uint256 marketPrice,
        int256 longAccFundingFeePerShare
    ) internal pure returns (int256 fundingFee) {
        int256 fundingFeeUsd;
        if (ot.isLong) {
            fundingFeeUsd = int256(ot.qty * marketPrice) * (longAccFundingFeePerShare - ot.longAccFundingFeePerShare) / 1e18;
        } else {
            fundingFeeUsd = int256(ot.qty * marketPrice) * (longAccFundingFeePerShare - ot.longAccFundingFeePerShare) * (- 1) / 1e18;
        }
        fundingFee = fundingFeeUsd * int256(10 ** mt.decimals) / int256(1e10 * mt.price);
        return fundingFee;
    }

    function increaseOpenTradeAmount(TradingStorage storage ts, address token, uint256 amount) internal {
        address[] storage tokenIns = ts.openTradeTokenIns;
        bool exists;
        for (UC i = ZERO; i < uc(tokenIns.length); i = i + ONE) {
            if (tokenIns[i.into()] == token) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            tokenIns.push(token);
        }
        ts.openTradeAmountIns[token] += amount;
    }
}