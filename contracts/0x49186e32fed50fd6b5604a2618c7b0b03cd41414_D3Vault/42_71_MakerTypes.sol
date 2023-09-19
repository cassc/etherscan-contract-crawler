// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {DecimalMath} from "./DecimalMath.sol";

library MakerTypes {
    struct MakerState {
        HeartBeat heartBeat;
        // price list to package prices in one slot
        PriceListInfo priceListInfo;
        // =============== Swap Storage =================
        mapping(address => TokenMMInfoWithoutCum) tokenMMInfoMap;
    }

    struct TokenMMInfoWithoutCum {
        // [mid price(16) | mid price decimal(8) | fee rate(16) | ask up rate (16) | bid down rate(16)]
        // midprice unit is 1e18
        // all rate unit is 10000
        uint80 priceInfo;
        // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
        uint64 amountInfo;
        // k is [0, 10000]
        uint16 kAsk;
        uint16 kBid;
        uint16 tokenIndex;
    }

    // package three token price in one slot
    struct PriceListInfo {
        // to avoid reset the same token, tokenIndexMap record index from 1, but actualIndex = tokenIndex[address] - 1
        // odd for none-stable, even for stable,  true index = actualIndex / 2 = (tokenIndex[address] - 1) / 2
        mapping(address => uint256) tokenIndexMap;
        uint256 numberOfNS; // quantity of not stable token
        uint256 numberOfStable; // quantity of stable token
        // [mid price(16) | mid price decimal(8) | fee rate(16) | ask up rate (16) | bid down rate(16)] = 72 bit
        // one slot contain = 72 * 3, 3 token price
        // [2 | 1 | 0]
        uint256[] tokenPriceNS; // not stable token price
        uint256[] tokenPriceStable; // stable token price
    }

    struct HeartBeat {
        uint256 lastHeartBeat;
        uint256 maxInterval;
    }

    uint16 internal constant ONE_PRICE_BIT = 72;
    uint256 internal constant PRICE_QUANTITY_IN_ONE_SLOT = 3;
    uint16 internal constant ONE_AMOUNT_BIT = 24;
    uint256 internal constant ONE = 10 ** 18;

    // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function parseAskAmount(uint64 amountInfo) internal pure returns (uint256 amountWithDecimal) {
        uint256 askAmount = (amountInfo >> (ONE_AMOUNT_BIT + 8)) & 0xffff;
        uint256 askAmountDecimal = (amountInfo >> ONE_AMOUNT_BIT) & 255;
        amountWithDecimal = askAmount * (10 ** askAmountDecimal);
    }

    // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function parseBidAmount(uint64 amountInfo) internal pure returns (uint256 amountWithDecimal) {
        uint256 bidAmount = (amountInfo >> 8) & 0xffff;
        uint256 bidAmountDecimal = amountInfo & 255;
        amountWithDecimal = bidAmount * (10 ** bidAmountDecimal);
    }

    function parseAllPrice(uint80 priceInfo, uint256 mtFeeRate)
        internal
        pure
        returns (uint256 askUpPrice, uint256 askDownPrice, uint256 bidUpPrice, uint256 bidDownPrice, uint256 swapFee)
    {
        {
        uint256 midPrice = (priceInfo >> 56) & 0xffff;
        uint256 midPriceDecimal = (priceInfo >> 48) & 255;
        uint256 midPriceWithDecimal = midPrice * (10 ** midPriceDecimal);

        uint256 swapFeeRate = (priceInfo >> 32) & 0xffff;
        uint256 askUpRate = (priceInfo >> 16) & 0xffff;
        uint256 bidDownRate = priceInfo & 0xffff;

        // swap fee rate standarlize
        swapFee = swapFeeRate * (10 ** 14) + mtFeeRate;
        uint256 swapFeeSpread = DecimalMath.mul(midPriceWithDecimal, swapFee);

        // ask price standarlize
        askDownPrice = midPriceWithDecimal + swapFeeSpread;
        askUpPrice = midPriceWithDecimal + midPriceWithDecimal * askUpRate / (10 ** 4);
        require(askDownPrice <= askUpPrice, "ask price invalid");

        // bid price standarlize
        uint reversalBidUp = midPriceWithDecimal - swapFeeSpread;
        uint reversalBidDown = midPriceWithDecimal - midPriceWithDecimal * bidDownRate / (10 ** 4);
        require(reversalBidDown <= reversalBidUp, "bid price invalid");
        bidDownPrice = DecimalMath.reciprocalCeil(reversalBidUp);
        bidUpPrice = DecimalMath.reciprocalCeil(reversalBidDown);
        }
    }

    function parseK(uint16 originK) internal pure returns (uint256) {
        return uint256(originK) * (10 ** 14);
    }
}