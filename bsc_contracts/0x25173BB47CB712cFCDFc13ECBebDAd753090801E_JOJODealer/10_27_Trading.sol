/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../intf/IPerpetual.sol";
import "../intf/IMarkPriceSource.sol";
import "../utils/SignedDecimalMath.sol";
import "../utils/Errors.sol";
import "./EIP712.sol";
import "./Types.sol";
import "./Liquidation.sol";
import "./Position.sol";

library Trading {
    using SignedDecimalMath for int256;
    using Math for uint256;

    // ========== events ==========

    /*
        orderFilledPaperAmount>0 and filledCreditAmount<0 if the order open long,
        and vice versa.
        filledCreditAmount including fees.
    */
    event OrderFilled(
        bytes32 indexed orderHash,
        address indexed trader,
        address indexed perp,
        int256 orderFilledPaperAmount,
        int256 filledCreditAmount,
        uint256 positionSerialNum
    );

    // ========== matching[important] ==========

    /// @notice calculate balance changes
    /// @dev Every matching contains 1 taker order and 
    /// at least 1 maker order.
    /// orderList[0] is taker order and all others are taker orders.
    /// Maker orders should be sorted by signer addresses in ascending.
    /// So that the function could merge orders to save gas.
    function _matchOrders(
        Types.State storage state,
        bytes32[] memory orderHashList,
        Types.Order[] memory orderList,
        uint256[] memory matchPaperAmount
    ) internal returns (Types.MatchResult memory result) {
        // check basic match paper amount and filter unique traders
        {
            require(orderList.length >= 2, Errors.INVALID_TRADER_NUMBER);
            // de-duplicated maker
            uint256 uniqueTraderNum = 2;
            uint256 totalMakerFilledPaper = matchPaperAmount[1];
            // start from the second maker, which is the third trader
            for (uint256 i = 2; i < orderList.length; i++) {
                totalMakerFilledPaper += matchPaperAmount[i];
                if (orderList[i].signer > orderList[i - 1].signer) {
                    uniqueTraderNum += 1;
                } else {
                    require(
                        orderList[i].signer == orderList[i - 1].signer,
                        Errors.ORDER_WRONG_SORTING
                    );
                }
            }
            // taker match amount must equals summary of makers' match amount
            require(
                matchPaperAmount[0] == totalMakerFilledPaper,
                Errors.TAKER_TRADE_AMOUNT_WRONG
            );
            // result.traderList[0] is taker
            // result.traderList[1:] are makers
            result.traderList = new address[](uniqueTraderNum);
            result.traderList[0] = orderList[0].signer;
        }

        // calculating balance change
        result.paperChangeList = new int256[](result.traderList.length);
        result.creditChangeList = new int256[](result.traderList.length);
        {
            // the taker's trader index is 0
            // the first maker's trader index is 1
            uint256 currentTraderIndex = 1;
            result.traderList[1] = orderList[1].signer;
            for (uint256 i = 1; i < orderList.length; ) {
                _priceMatchCheck(orderList[0], orderList[i]);

                // new maker, currentTraderIndex +1
                if (i >= 2 && orderList[i].signer != orderList[i - 1].signer) {
                    currentTraderIndex += 1;
                    result.traderList[currentTraderIndex] = orderList[i].signer;
                }

                // calculate matching result, use maker's price
                int256 paperChange = orderList[i].paperAmount > 0
                    ? int256(matchPaperAmount[i])
                    : -1 * int256(matchPaperAmount[i]);
                int256 creditChange = (paperChange *
                    orderList[i].creditAmount) / orderList[i].paperAmount;
                int256 fee = int256(creditChange.abs()).decimalMul(
                    _info2MakerFeeRate(orderList[i].info)
                );
                // serialNum is used for frontend level PNL calculation
                uint256 serialNum = state.positionSerialNum[
                    orderList[i].signer
                ][msg.sender];
                emit OrderFilled(
                    orderHashList[i],
                    orderList[i].signer,
                    msg.sender,
                    paperChange,
                    creditChange - fee,
                    serialNum
                );
                // store matching result, including fees
                result.paperChangeList[currentTraderIndex] += paperChange;
                result.creditChangeList[currentTraderIndex] += creditChange - fee;
                result.paperChangeList[0] -= paperChange;
                result.creditChangeList[0] -= creditChange;
                result.orderSenderFee += fee;

                unchecked {
                    ++i;
                }
            }
        }

        // trading fee calculation
        {
            // calculate takerFee based on taker's credit matching amount
            int256 takerFee = int256(result.creditChangeList[0].abs())
                .decimalMul(_info2TakerFeeRate(orderList[0].info));
            result.creditChangeList[0] -= takerFee;
            result.orderSenderFee += takerFee;
            emit OrderFilled(
                orderHashList[0],
                orderList[0].signer,
                msg.sender,
                result.paperChangeList[0],
                result.creditChangeList[0],
                state.positionSerialNum[orderList[0].signer][msg.sender]
            );
        }
    }

    // ========== order check ==========

    function _priceMatchCheck(
        Types.Order memory takerOrder,
        Types.Order memory makerOrder
    ) private pure {
        /*
            Requirements:
            takercredit * abs(makerpaper) / abs(takerpaper) + makercredit <= 0
            makercredit - takercredit * makerpaper / takerpaper <= 0
            if takerPaper > 0
            makercredit * takerpaper <= takercredit * makerpaper
            if takerPaper < 0
            makercredit * takerpaper >= takercredit * makerpaper
        */

        // let temp1 = makercredit * takerpaper
        // let temp2 = takercredit * makerpaper
        int256 temp1 = int256(makerOrder.creditAmount) *
            int256(takerOrder.paperAmount);
        int256 temp2 = int256(takerOrder.creditAmount) *
            int256(makerOrder.paperAmount);

        if (takerOrder.paperAmount > 0) {
            // maker order should be in the opposite direction of taker order
            require(makerOrder.paperAmount < 0, Errors.ORDER_PRICE_NOT_MATCH);
            require(temp1 <= temp2, Errors.ORDER_PRICE_NOT_MATCH);
        } else {
            // maker order should be in the opposite direction of taker order
            require(makerOrder.paperAmount > 0, Errors.ORDER_PRICE_NOT_MATCH);
            require(temp1 >= temp2, Errors.ORDER_PRICE_NOT_MATCH);
        }
    }

    // ========== EIP712 struct hash ==========

    function _structHash(Types.Order memory order)
        internal
        pure
        returns (bytes32 structHash)
    {
        /*
            To save gas, we use assembly to implement the function:

            keccak256(
                abi.encode(
                    Types.ORDER_TYPEHASH,
                    order.perp,
                    order.signer,
                    order.paperAmount,
                    order.creditAmount,
                    order.info
                )
            )

            This is equivalent to:
            Insert ORDER_TYPEHASH before order's memory head. And then
            hash the whole memory section.
            Finally, restore the memory slot occupied by ORDER_TYPEHASH.
        */

        bytes32 orderTypeHash = Types.ORDER_TYPEHASH;
        assembly {
            let start := sub(order, 32)
            let tmp := mload(start)
            // 192 = (1 + 5) * 32
            // [0...32)   bytes: EIP712_ORDER_TYPE
            // [32...192) bytes: order
            mstore(start, orderTypeHash)
            structHash := keccak256(start, 192)
            mstore(start, tmp)
        }
    }

    // ========== parse fee rates from info ==========

    function _info2MakerFeeRate(bytes32 info) internal pure returns (int256) {
        bytes8 value = bytes8(info >> 192);
        int64 makerFee;
        assembly {
            makerFee := value
        }
        return int256(makerFee);
    }

    function _info2TakerFeeRate(bytes32 info)
        internal
        pure
        returns (int256 takerFeeRate)
    {
        bytes8 value = bytes8(info >> 128);
        int64 takerFee;
        assembly {
            takerFee := value
        }
        return int256(takerFee);
    }

    function _info2Expiration(bytes32 info) internal pure returns (uint256) {
        bytes8 value = bytes8(info >> 64);
        uint64 expiration;
        assembly {
            expiration := value
        }
        return uint256(expiration);
    }
}