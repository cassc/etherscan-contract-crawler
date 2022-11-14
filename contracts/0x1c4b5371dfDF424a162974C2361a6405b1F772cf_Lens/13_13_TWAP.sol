// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./OrderLib.sol";
import "./IExchange.sol";

/**
 * ---------------------------
 * Time-Weighted Average Price
 * ---------------------------
 *
 * https://github.com/orbs-network/twap
 *
 * This smart contract allows the incentivized execution of a TWAP order (either a Limit Order or a Market Order) on any DEX, with the possibility of partial fills.
 *
 * A TWAP order breaks a larger order down into smaller trades or "chunks", which are executed over a set period of time.
 * This is a common strategy in traditional finance but it was not previously possible to execute such trades in a decentralized manner in DeFi systems.
 *
 * In this smart contract, users (makers) create orders that wait in the contract to be filled. Once made, these orders enable an English Auction bidding war on each chunk at its time interval.
 * Anyone willing to participate can serve as a “taker” by finding the best path to fill the order for the next chunk on any DEX,
 * within the parameters set by the maker. Takers submit these paths as a bid to the contract, which selects the winner based on criteria described in detail below.
 *
 * The winning taker receives a portion of the output tokens as a reward for their effort.
 *
 * One honest taker (i.e., a taker who is willing to set the fee at the minimum amount needed to cover gas costs)
 * is enough to ensure the entire system functions effectively at spot prices.
 *
 * The contract is set to operate only up to the year 2106 (32bit timestamps), at which point it will no longer be usable.
 *
 * The TWAP Smart Contract does not hold any funds, has no owners, administrators, or other roles and is entirely immutable once deployed on an EVM blockchain.
 *
 */
contract TWAP is ReentrancyGuard {
    using SafeERC20 for ERC20;
    using Address for address;
    using OrderLib for OrderLib.Order;

    uint8 public constant VERSION = 1;

    event OrderCreated(uint64 indexed id, address indexed maker, address indexed exchange, OrderLib.Ask ask);
    event OrderBid(
        uint64 indexed id,
        address indexed maker,
        address indexed exchange,
        uint32 slippagePercent,
        OrderLib.Bid bid
    );
    event OrderFilled(
        uint64 indexed id,
        address indexed maker,
        address indexed exchange,
        address taker,
        uint256 srcAmountIn,
        uint256 dstAmountOut,
        uint256 dstFee,
        uint256 srcFilledAmount
    );
    event OrderCompleted(uint64 indexed id, address indexed maker, address indexed exchange, address taker);
    event OrderCanceled(uint64 indexed id, address indexed maker, address sender);

    uint32 public constant PERCENT_BASE = 100_000;
    uint32 public constant MIN_OUTBID_PERCENT = 101_000;
    uint32 public constant STALE_BID_DELAY_MUL = 5; // multiplier on bidDelay before a bid is considered stale
    uint32 public constant MIN_BID_DELAY_SECONDS = 10;
    uint32 public constant MIN_FILL_DELAY_SECONDS = 60;

    uint32 public constant STATUS_CANCELED = 1;
    uint32 public constant STATUS_COMPLETED = 2;

    OrderLib.Order[] public book;
    uint32[] public status; // STATUS or deadline timestamp by order id, used for gas efficient order filtering
    mapping(address => uint64[]) public makerOrders;

    // -------- views --------

    /**
     * returns Order by order id
     */
    function order(uint64 id) public view returns (OrderLib.Order memory) {
        require(id < length(), "invalid id");
        return book[id];
    }

    /**
     * returns order book length
     */
    function length() public view returns (uint64) {
        return uint64(book.length);
    }

    function orderIdsByMaker(address maker) external view returns (uint64[] memory) {
        return makerOrders[maker];
    }

    // -------- actions --------

    /**
     * Create Order by msg.sender (maker)
     * exchange: when 0 address order can be swapped on any exchange, otherwise only that specific exchange
     * srcToken: swap from token
     * dstToken: swap to token
     * srcAmount: total order amount in srcToken
     * srcBidAmount: chunk size in srcToken
     * dstMinAmount: minimum amount out per chunk in dstToken
     * deadline: order expiration
     * bidDelay: minimum seconds before a bid can be filled
     * fillDelay: minimum seconds between chunk fills
     * returns order id, emits OrderCreated
     */
    function ask(
        address exchange,
        address srcToken,
        address dstToken,
        uint256 srcAmount,
        uint256 srcBidAmount,
        uint256 dstMinAmount,
        uint32 deadline,
        uint32 bidDelay,
        uint32 fillDelay
    ) external nonReentrant returns (uint64 id) {
        require(
            srcToken != address(0) &&
                dstToken != address(0) &&
                srcToken != dstToken &&
                srcAmount > 0 &&
                srcBidAmount > 0 &&
                srcBidAmount <= srcAmount &&
                dstMinAmount > 0 &&
                deadline > block.timestamp &&
                bidDelay >= MIN_BID_DELAY_SECONDS &&
                fillDelay >= MIN_FILL_DELAY_SECONDS &&
                bidDelay <= fillDelay,
            "params"
        );

        OrderLib.Order memory o = OrderLib.newOrder(
            length(),
            deadline,
            bidDelay,
            fillDelay,
            exchange,
            srcToken,
            dstToken,
            srcAmount,
            srcBidAmount,
            dstMinAmount
        );

        verifyMakerBalance(o);

        book.push(o);
        status.push(deadline);
        makerOrders[msg.sender].push(o.id);
        emit OrderCreated(o.id, msg.sender, exchange, o.ask);
        return o.id;
    }

    /**
     * Bid for a specific order by id (msg.sender is taker)
     * A valid bid is higher than current bid, with sufficient price after fees and after last fill delay. Invalid bids are reverted.
     * id: order id
     * exchange: bid to swap on exchange
     * dstFee: fee to traker in dstToken, taken from the swapped amount
     * slippagePercent: price output difference tolerance percent / 100,000. 0 means no slippage
     * data: swap data to pass to the exchange, for example the route path
     * emits OrderBid event
     */
    function bid(
        uint64 id,
        address exchange,
        uint256 dstFee,
        uint32 slippagePercent,
        bytes calldata data
    ) external nonReentrant {
        require(exchange != address(0) && slippagePercent < PERCENT_BASE, "params");
        OrderLib.Order memory o = order(id);
        uint256 dstAmountOut = verifyBid(o, exchange, dstFee, slippagePercent, data);
        o.newBid(exchange, dstAmountOut, dstFee, data);
        book[id] = o;
        emit OrderBid(o.id, o.ask.maker, exchange, slippagePercent, o.bid);
    }

    /**
     * Fill the current winning bid by the winning taker, if after the bidding window. Invalid fills are reverted.
     * id: order id
     * emits OrderFilled
     * if order is fully filled emits OrderCompleted and status is updated
     */
    function fill(uint64 id) external nonReentrant {
        OrderLib.Order memory o = order(id);

        (address exchange, uint256 srcAmountIn, uint256 dstAmountOut, uint256 dstFee) = performFill(o);
        o.filled(srcAmountIn);

        emit OrderFilled(id, o.ask.maker, exchange, msg.sender, srcAmountIn, dstAmountOut, dstFee, o.srcFilledAmount);

        if (o.srcBidAmountNext() == 0) {
            status[id] = STATUS_COMPLETED;
            o.status = STATUS_COMPLETED;
            emit OrderCompleted(o.id, o.ask.maker, exchange, msg.sender);
        }
        book[id] = o;
    }

    /**
     * Cancel order by id, only callable by maker
     * id: order id
     * emits OrderCanceled
     */
    function cancel(uint64 id) external nonReentrant {
        OrderLib.Order memory o = order(id);
        require(msg.sender == o.ask.maker, "maker");
        status[id] = STATUS_CANCELED;
        o.status = STATUS_CANCELED;
        book[id] = o;
        emit OrderCanceled(o.id, o.ask.maker, msg.sender);
    }

    /**
     * Called by anyone to mark a stale invalid order as canceled
     * id: order id
     * emits OrderCanceled
     */
    function prune(uint64 id) external nonReentrant {
        OrderLib.Order memory o = order(id);
        require(block.timestamp < o.status, "status");
        require(block.timestamp > o.filledTime + o.ask.fillDelay, "fill delay");
        require(
            ERC20(o.ask.srcToken).allowance(o.ask.maker, address(this)) < o.srcBidAmountNext() ||
                ERC20(o.ask.srcToken).balanceOf(o.ask.maker) < o.srcBidAmountNext(),
            "valid"
        );
        status[id] = STATUS_CANCELED;
        o.status = STATUS_CANCELED;
        book[id] = o;
        emit OrderCanceled(o.id, o.ask.maker, msg.sender);
    }

    /**
     * ---- internals ----
     */

    /**
     * verifies the bid against the ask params, reverts on invalid bid.
     * returns dstAmountOut after taker dstFee, which must be higher than any previous bid, unless previous bid is stale
     */
    function verifyBid(
        OrderLib.Order memory o,
        address exchange,
        uint256 dstFee,
        uint32 slippagePercent,
        bytes calldata data
    ) private view returns (uint256 dstAmountOut) {
        require(block.timestamp < o.status, "status"); // deadline, canceled or completed
        require(block.timestamp > o.filledTime + o.ask.fillDelay, "fill delay");
        require(o.ask.exchange == address(0) || o.ask.exchange == exchange, "exchange");

        dstAmountOut = IExchange(exchange).getAmountOut(o.ask.srcToken, o.ask.dstToken, o.srcBidAmountNext(), data);
        dstAmountOut -= (dstAmountOut * slippagePercent) / PERCENT_BASE;
        dstAmountOut -= dstFee;

        require(
            dstAmountOut > (o.bid.dstAmount * MIN_OUTBID_PERCENT) / PERCENT_BASE || // outbid by more than MIN_OUTBID_PERCENT
                block.timestamp > o.bid.time + (o.ask.bidDelay * STALE_BID_DELAY_MUL), // or stale bid
            "low bid"
        );
        require(dstAmountOut >= o.dstMinAmountNext(), "min out");
        verifyMakerBalance(o);
    }

    /**
     * executes the winning bid. reverts if bid no longer valid.
     * transfers next chunk srcToken amount from maker, swaps via bid exchange with bid data, transfers dstFee to taker (msg.sender) and
     * transfers all other dstToken amount to maker
     */
    function performFill(
        OrderLib.Order memory o
    ) private returns (address exchange, uint256 srcAmountIn, uint256 dstAmountOut, uint256 dstFee) {
        require(msg.sender == o.bid.taker, "taker");
        require(block.timestamp < o.status, "status"); // deadline, canceled or completed
        require(block.timestamp > o.bid.time + o.ask.bidDelay, "bid delay");

        exchange = o.bid.exchange;
        dstFee = o.bid.dstFee;
        srcAmountIn = o.srcBidAmountNext();
        uint256 minOut = o.dstExpectedOutNext();

        ERC20(o.ask.srcToken).safeTransferFrom(o.ask.maker, address(this), srcAmountIn);
        srcAmountIn = ERC20(o.ask.srcToken).balanceOf(address(this)); // support FoT tokens
        ERC20(o.ask.srcToken).safeIncreaseAllowance(exchange, srcAmountIn);

        IExchange(exchange).swap(o.ask.srcToken, o.ask.dstToken, srcAmountIn, minOut + dstFee, o.bid.data);
        dstAmountOut = ERC20(o.ask.dstToken).balanceOf(address(this)); // support FoT tokens
        dstAmountOut -= dstFee;
        require(dstAmountOut >= minOut, "min out");

        ERC20(o.ask.dstToken).safeTransfer(o.bid.taker, dstFee);
        ERC20(o.ask.dstToken).safeTransfer(o.ask.maker, dstAmountOut);
    }

    /**
     * reverts if maker does not hold enough balance srcToken or allowance to be spent here for the next chunk
     */
    function verifyMakerBalance(OrderLib.Order memory o) private view {
        require(ERC20(o.ask.srcToken).allowance(o.ask.maker, address(this)) >= o.srcBidAmountNext(), "maker allowance");
        require(ERC20(o.ask.srcToken).balanceOf(o.ask.maker) >= o.srcBidAmountNext(), "maker balance");
    }
}