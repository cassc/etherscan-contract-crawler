// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ITradingCore.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

library LibTradingCore {

    using SignedMath for int256;

    bytes32 constant TRADING_CORE_POSITION = keccak256("apollox.trading.core.storage");

    struct TradingCoreStorage {
        // pair.pairBase =>
        mapping(address => ITradingCore.PairPositionInfo) pairPositionInfos;
        // pair.base[]
        address[] hasPositionPairs;
    }

    function tradingCoreStorage() internal pure returns (TradingCoreStorage storage tcs) {
        bytes32 position = TRADING_CORE_POSITION;
        assembly {
            tcs.slot := position
        }
    }

    function fundingFeeRate(
        ITradingCore.PairPositionInfo memory ppi, address pairBase
    ) internal view returns (int256) {
        IPairsManager.PairMaxOiAndFundingFeeConfig memory pairConfig = IPairsManager(address(this)).getPairConfig(pairBase);
        int256 fundingFeeR;
        if (ppi.longQty != ppi.shortQty) {
            fundingFeeR = int256((int256(ppi.longQty) - int256(ppi.shortQty)).abs() * pairConfig.fundingFeePerBlockP) / (int256(ppi.longQty).max(int256(ppi.shortQty)));
            fundingFeeR = int256(pairConfig.maxFundingFeeR).min(int256(pairConfig.minFundingFeeR).max(fundingFeeR));
            if (ppi.longQty < ppi.shortQty) {
                fundingFeeR *= (- 1);
            }
        }
        return fundingFeeR;
    }
}