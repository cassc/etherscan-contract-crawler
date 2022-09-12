// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../OrderLib.sol";
import "../TWAP.sol";

/**
 * Helper contract to allow for efficient paginated filtered reads of Orders, instead of relying on events
 */
contract Lens {
    using OrderLib for OrderLib.Order;

    TWAP public immutable twap;

    constructor(address _twap) {
        twap = TWAP(_twap);
    }

    function length() public view returns (uint64) {
        return twap.length();
    }

    /**
     * returns all orders waiting to be bid on now by the taker, paginated
     * taker: desired taker
     * lastIndex: last order id, start with length-1
     * pageSize: size of iteration restricted by block gas limit. 2500 is measured to be < 15m gas
     */
    function takerBiddableOrders(
        address taker,
        uint64 lastIndex,
        uint64 pageSize
    ) external view returns (OrderLib.Order[] memory result) {
        OrderLib.Order[] memory orders = paginated(lastIndex, pageSize);
        uint64 count = 0;

        for (uint64 i = 0; i < orders.length; i++) {
            uint64 id = lastIndex - i;
            if (block.timestamp < twap.status(id)) {
                OrderLib.Order memory o = twap.order(id);
                if (
                    block.timestamp > o.filledTime + o.ask.delay && // after delay
                    (o.bid.taker != taker || block.timestamp > o.bid.time + twap.MAX_BID_WINDOW_SECONDS()) && // other taker or stale bid
                    ERC20(o.ask.srcToken).allowance(o.ask.maker, address(twap)) >= o.srcBidAmountNext() && // maker allowance
                    ERC20(o.ask.srcToken).balanceOf(o.ask.maker) >= o.srcBidAmountNext() // maker balance
                ) {
                    orders[count] = o;
                    count++;
                }
            }
        }

        result = new OrderLib.Order[](count);
        for (uint64 i = 0; i < count; i++) {
            result[i] = orders[i];
        }
    }

    /**
     * returns all orders waiting to be filled now by the taker, paginated
     * taker: desired taker
     * lastIndex: last order id, start with length-1
     * pageSize: size of iteration restricted by block gas limit. 2500 is measured to be < 15m gas
     */
    function takerFillableOrders(
        address taker,
        uint64 lastIndex,
        uint64 pageSize
    ) external view returns (OrderLib.Order[] memory result) {
        OrderLib.Order[] memory orders = paginated(lastIndex, pageSize);
        uint64 count = 0;

        for (uint64 i = 0; i < orders.length; i++) {
            uint64 id = lastIndex - i;
            if (block.timestamp < twap.status(id)) {
                OrderLib.Order memory o = twap.order(id);
                if (
                    o.bid.taker == taker && // winning taker
                    block.timestamp > o.bid.time + twap.MIN_BID_WINDOW_SECONDS() && // not pending bid
                    ERC20(o.ask.srcToken).allowance(o.ask.maker, address(twap)) >= o.srcBidAmountNext() && // maker allowance
                    ERC20(o.ask.srcToken).balanceOf(o.ask.maker) >= o.srcBidAmountNext() // maker balance
                ) {
                    orders[count] = o;
                    count++;
                }
            }
        }

        result = new OrderLib.Order[](count);
        for (uint64 i = 0; i < count; i++) {
            result[i] = orders[i];
        }
    }

    function paginated(uint64 lastIndex, uint64 pageSize) private view returns (OrderLib.Order[] memory) {
        require(lastIndex < length(), "lastIndex");
        return new OrderLib.Order[](Math.min(lastIndex + 1, pageSize));
    }
}