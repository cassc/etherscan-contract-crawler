// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";

library OrderLib {
    struct Order {
        uint64 id; // order id
        uint32 status; // status: deadline, canceled or completed
        uint32 filledTime; // last fill timestamp
        uint256 srcFilledAmount; // srcToken total filled amount
        Ask ask; // order ask parameters
        Bid bid; // current winning bid
    }

    struct Ask {
        uint32 time; // order creation timestamp
        uint32 deadline; // order duration timestamp
        uint32 delay; // minimum delay in seconds between chunks
        address maker; // order creator
        address exchange; // swap only on this exchange, or zero for any exchange
        address srcToken; // input token
        address dstToken; // output token
        uint256 srcAmount; // input total order amount
        uint256 srcBidAmount; // input chunk size
        uint256 dstMinAmount; // minimum output chunk size
    }

    struct Bid {
        uint32 time; // bid creation timestamp
        address taker; // bidder
        address exchange; // execute bid on this exchange, never zero
        uint256 dstAmount; // dstToken actual output amount for this bid after exchange fees, taker fee and buffer tolerance
        uint256 dstFee; // dstToken requested by taker for performing the bid and fill
        bytes data; // swap data to pass to exchange, out dstToken==dstAmount+dstFee
    }

    /**
     * new Order for msg.sender
     */
    function newOrder(
        uint64 id,
        uint32 deadline,
        uint32 delay,
        address exchange,
        address srcToken,
        address dstToken,
        uint256 srcAmount,
        uint256 srcBidAmount,
        uint256 dstMinAmount
    ) internal view returns (Order memory) {
        require(block.timestamp < type(uint32).max, "time");
        require(deadline < type(uint32).max && delay < type(uint32).max, "uint32");
        return
            Order(
                id,
                deadline, // status
                0, // filledTime
                0, // srcFilledAmount
                Ask(
                    uint32(block.timestamp),
                    deadline,
                    delay,
                    msg.sender,
                    exchange,
                    srcToken,
                    dstToken,
                    srcAmount,
                    srcBidAmount,
                    dstMinAmount
                ),
                Bid(
                    0, // time
                    address(0), // taker
                    address(0), // exchange
                    0, // dstAmount
                    0, // dstFee
                    new bytes(0) // data
                )
            );
    }

    /**
     * new Bid
     */
    function newBid(
        Order memory self,
        address exchange,
        uint256 dstAmountOut,
        uint256 dstFee,
        bytes memory data
    ) internal view {
        require(block.timestamp < type(uint32).max, "time");
        self.bid = OrderLib.Bid(uint32(block.timestamp), msg.sender, exchange, dstAmountOut, dstFee, data);
    }

    /**
     * chunk filled
     */
    function filled(Order memory self, uint256 srcAmountIn) internal view {
        require(block.timestamp < type(uint32).max, "time");
        delete self.bid;
        self.filledTime = uint32(block.timestamp);
        self.srcFilledAmount += srcAmountIn;
    }

    /**
     * next chunk srcToken: either ask.srcBidAmount or leftover
     */
    function srcBidAmountNext(Order memory self) internal pure returns (uint256) {
        return Math.min(self.ask.srcBidAmount, self.ask.srcAmount - self.srcFilledAmount);
    }

    /**
     * next chunk dstToken minimum amount out
     */
    function dstMinAmountNext(Order memory self) internal pure returns (uint256) {
        return (self.ask.dstMinAmount * srcBidAmountNext(self)) / self.ask.srcBidAmount;
    }

    /**
     * next chunk expected output in dstToken, or winning bid
     */
    function dstExpectedOutNext(Order memory self) internal pure returns (uint256) {
        return Math.max(self.bid.dstAmount, dstMinAmountNext(self));
    }
}