// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;
import {IOrderbookFactory} from "./interfaces/IOrderbookFactory.sol";
import {IOrderbook, ExchangeOrderbook} from "./interfaces/IOrderbook.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IRevenue {
    function report(
        uint32 uid,
        address token,
        uint256 amount,
        bool isAdd
    ) external;

    function isReportable(
        address token,
        uint32 uid
    ) external view returns (bool);

    function refundFee(address to, address token, uint256 amount) external;

    function feeOf(uint32 uid, bool isMaker) external returns (uint32 feeNum);
}

// Onchain Matching engine for the orders
contract MatchingEngine is Initializable, ReentrancyGuard {
    // fee recipient
    address private feeTo;
    // fee denominator
    uint32 public immutable feeDenom = 1000000;
    // Factories
    address public orderbookFactory;
    // WETH
    address public WETH;

    // events
    event OrderCanceled(
        address orderbook,
        uint256 id,
        bool isBid,
        address indexed owner
    );

    event OrderMatched(
        address orderbook,
        uint256 id,
        bool isBid,
        address sender,
        address indexed owner,
        uint256 amount,
        uint256 price
    );

    event OrderPlaced(
        address indexed base,
        address indexed quote,
        bool indexed isBid,
        uint256 orderId
    );

    event PairAdded(
        address orderbook,
        address base,
        address quote
    );

    error TooManyMatches(uint256 n);
    error InvalidFeeRate(uint256 feeNum, uint256 feeDenom);
    error NotContract(address newImpl);
    error InvalidRole(bytes32 role, address sender);
    error OrderSizeTooSmall(uint256 amount, uint256 minRequired);

    constructor() {}

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /**
     * @dev Initialize the matching engine with orderbook factory and listing requirements.
     * It can be called only once.
     * @param orderbookFactory_ address of orderbook factory
     * @param revenue_ address of revenue contract
     * @param WETH_ address of wrapped ether contract
     *
     * Requirements:
     * - `msg.sender` must have the default admin role.
     */
    function initialize(
        address orderbookFactory_,
        address revenue_,
        address WETH_
    ) external initializer {
        orderbookFactory = orderbookFactory_;
        feeTo = revenue_;
        WETH = WETH_;
    }

    /**
     * @dev Executes a market buy order,
     * buys the base asset using the quote asset at the best available price in the orderbook up to `n` orders,
     * and make an order at the market price.
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @param quoteAmount The amount of quote asset to be used for the market buy order
     * @param isMaker Boolean indicating if a order should be made at the market price in orderbook
     * @param n The maximum number of orders to match in the orderbook
     * @return bool True if the order was successfully executed, otherwise false.
     */
    function marketBuy(
        address base,
        address quote,
        uint256 quoteAmount,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) public nonReentrant returns (bool) {
        (uint256 withoutFee, address orderbook) = _deposit(
            base,
            quote,
            0,
            quoteAmount,
            true,
            uid,
            isMaker
        );
        // negate on give if the asset is not the base
        uint256 lmp;
        // reuse withoutFee variable due to stack too deep error
        (withoutFee, lmp) = _limitOrder(
            orderbook,
            withoutFee,
            quote,
            true,
            type(uint256).max,
            n
        );
        // add make order on market price

        _detMake(
            base,
            quote,
            orderbook,
            withoutFee,
            lmp == 0 ? mktPrice(base, quote) : lmp,
            true,
            isMaker
        );
        return true;
    }

    /**
     * @dev Executes a market sell order,
     * sells the base asset for the quote asset at the best available price in the orderbook up to `n` orders,
     * and make an order at the market price.
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @param baseAmount The amount of base asset to be sold in the market sell order
     * @param isMaker Boolean indicating if an order should be made at the market price in orderbook
     * @param n The maximum number of orders to match in the orderbook
     * @return bool True if the order was successfully executed, otherwise false.
     */
    function marketSell(
        address base,
        address quote,
        uint256 baseAmount,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) public nonReentrant returns (bool) {
        (uint256 withoutFee, address orderbook) = _deposit(
            base,
            quote,
            0,
            baseAmount,
            false,
            uid,
            isMaker
        );
        // negate on give if the asset is not the base
        uint256 lmp;
        // reuse withoutFee variable for storing remaining amount after matching due to stack too deep error
        (withoutFee, lmp) = _limitOrder(
            orderbook,
            withoutFee,
            base,
            false,
            0,
            n
        );
        _detMake(
            base,
            quote,
            orderbook,
            withoutFee,
            lmp == 0 ? mktPrice(base, quote) : lmp,
            false,
            isMaker
        );
        return true;
    }

    /**
     * @dev Executes a market buy order,
     * buys the base asset using the quote asset at the best available price in the orderbook up to `n` orders,
     * and make an order at the market price with quote asset as native Ethereum(or other network currencies).
     * @param base The address of the base asset for the trading pair
     * @param isMaker Boolean indicating if a order should be made at the market price in orderbook
     * @param n The maximum number of orders to match in the orderbook
     * @return bool True if the order was successfully executed, otherwise false.
     */
    function marketBuyETH(
        address base,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) external payable returns (bool) {
        IWETH(WETH).deposit{value: msg.value}();
        return marketBuy(base, WETH, msg.value, isMaker, n, uid);
    }

    /**
     * @dev Executes a market sell order,
     * sells the base asset for the quote asset at the best available price in the orderbook up to `n` orders,
     * and make an order at the market price with base asset as native Ethereum(or other network currencies).
     * @param quote The address of the quote asset for the trading pair
     * @param isMaker Boolean indicating if an order should be made at the market price in orderbook
     * @param n The maximum number of orders to match in the orderbook
     * @return bool True if the order was successfully executed, otherwise false.
     */
    function marketSellETH(
        address quote,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) external payable returns (bool) {
        IWETH(WETH).deposit{value: msg.value}();
        return marketSell(WETH, quote, msg.value, isMaker, n, uid);
    }

    /**
     * @dev Executes a limit buy order,
     * places a limit order in the orderbook for buying the base asset using the quote asset at a specified price,
     * and make an order at the limit price.
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @param price The price, base/quote regardless of decimals of the assets in the pair represented with 8 decimals (if 1000, base is 1000x quote)
     * @param quoteAmount The amount of quote asset to be used for the limit buy order
     * @param isMaker Boolean indicating if an order should be made at the limit price
     * @param n The maximum number of orders to match in the orderbook
     * @return bool True if the order was successfully executed, otherwise false.
     */
    function limitBuy(
        address base,
        address quote,
        uint256 price,
        uint256 quoteAmount,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) public nonReentrant returns (bool) {
        (uint256 withoutFee, address orderbook) = _deposit(
            base,
            quote,
            price,
            quoteAmount,
            true,
            uid,
            isMaker
        );
        // negate on give if the asset is not the base
        uint256 lmp;
        // reuse withoutFee variable for storing remaining amount after matching due to stack too deep error
        (withoutFee, lmp) = _limitOrder(
            orderbook,
            withoutFee,
            quote,
            true,
            price,
            n
        );

        _detMake(
            base,
            quote,
            orderbook,
            withoutFee,
            lmp == 0 ? price : lmp,
            true,
            isMaker
        );
        return true;
    }

    /**
     * @dev Executes a limit sell order,
     * places a limit order in the orderbook for selling the base asset for the quote asset at a specified price,
     * and makes an order at the limit price.
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @param price The price, base/quote regardless of decimals of the assets in the pair represented with 8 decimals (if 1000, base is 1000x quote)
     * @param baseAmount The amount of base asset to be used for the limit sell order
     * @param isMaker Boolean indicating if an order should be made at the limit price
     * @param n The maximum number of orders to match in the orderbook
     * @return bool True if the order was successfully executed, otherwise false.
     */
    function limitSell(
        address base,
        address quote,
        uint256 price,
        uint256 baseAmount,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) public nonReentrant returns (bool) {
        (uint256 withoutFee, address orderbook) = _deposit(
            base,
            quote,
            price,
            baseAmount,
            false,
            uid,
            isMaker
        );
        // negate on give if the asset is not the base
        uint256 lmp;
        // reuse withoutFee variable for storing remaining amount after matching due to stack too deep error
        (withoutFee, lmp) = _limitOrder(
            orderbook,
            withoutFee,
            base,
            false,
            price,
            n
        );
        _detMake(
            base,
            quote,
            orderbook,
            withoutFee,
            lmp == 0 ? price : lmp,
            false,
            isMaker
        );
        return true;
    }

    /**
     * @dev Executes a limit buy order,
     * places a limit order in the orderbook for buying the base asset using the quote asset at a specified price,
     * and make an order at the limit price with quote asset as native Ethereum(or network currencies).
     * @param base The address of the base asset for the trading pair
     * @param isMaker Boolean indicating if a order should be made at the market price in orderbook
     * @param n The maximum number of orders to match in the orderbook
     * @return bool True if the order was successfully executed, otherwise false.
     */
    function limitBuyETH(
        address base,
        uint256 price,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) external payable returns (bool) {
        IWETH(WETH).deposit{value: msg.value}();
        return limitBuy(base, WETH, price, msg.value, isMaker, n, uid);
    }

    /**
     * @dev Executes a limit sell order,
     * places a limit order in the orderbook for selling the base asset for the quote asset at a specified price,
     * and makes an order at the limit price with base asset as native Ethereum(or network currencies).
     * @param quote The address of the quote asset for the trading pair
     * @param isMaker Boolean indicating if an order should be made at the market price in orderbook
     * @param n The maximum number of orders to match in the orderbook
     * @return bool True if the order was successfully executed, otherwise false.
     */
    function limitSellETH(
        address quote,
        uint256 price,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) external payable returns (bool) {
        IWETH(WETH).deposit{value: msg.value}();
        return limitSell(WETH, quote, price, msg.value, isMaker, n, uid);
    }

    /**
     * @dev Creates an orderbook for a new trading pair and returns its address
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @return book The address of the newly created orderbook
     */
    function addPair(
        address base,
        address quote
    ) public returns (address book) {
        // create orderbook for the pair
        address orderBook = IOrderbookFactory(orderbookFactory).createBook(
            base,
            quote
        );
        emit PairAdded(orderBook, base, quote);
        return orderBook;
    }

    /**
     * @dev Cancels an order in an orderbook by the given order ID and order type.
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @param orderId The ID of the order to cancel
     * @param isBid Boolean indicating if the order to cancel is an ask order
     * @return bool True if the order was successfully canceled, otherwise false.
     */
    function cancelOrder(
        address base,
        address quote,
        uint256 price,
        uint32 orderId,
        bool isBid,
        uint32 uid
    ) public nonReentrant returns (bool) {
        address orderbook = IOrderbookFactory(orderbookFactory).getBookByPair(
            base,
            quote
        );
        uint256 remaining = IOrderbook(orderbook).cancelOrder(
            isBid,
            price,
            orderId,
            msg.sender
        );
        // decrease point from orderbook
        if (uid != 0 && IRevenue(feeTo).isReportable(msg.sender, uid)) {
            // report cancelation to accountant
            IRevenue(feeTo).report(
                uid,
                isBid ? quote : base,
                remaining,
                false
            );
            // refund fee from treasury to sender
            IRevenue(feeTo).refundFee(
                msg.sender,
                isBid ? quote : base,
                (remaining * 100) / feeDenom
            );
        }

        emit OrderCanceled(orderbook, orderId, isBid, msg.sender);
        return true;
    }

    function cancelOrders(
        address[] memory base,
        address[] memory quote,
        uint256[] memory prices,
        uint32[] memory orderIds,
        bool[] memory isBid,
        uint32 uid
    ) external returns (bool) {
        for (uint32 i = 0; i < orderIds.length; i++) {
            cancelOrder(
                base[i],
                quote[i],
                prices[i],
                orderIds[i],
                isBid[i],
                uid
            );
        }
        return true;
    }

    /**
     * @dev Cancels an order in an orderbook by the given order ID and order type.
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @param price The price of the order to rematch
     * @param orderId The ID of the order to cancel
     * @param isBid Boolean indicating if the order to cancel is an ask order
     * @param uid The ID of the user
     * @return bool True if the order was successfully rematched, otherwise false.
     */
    function rematchOrder(
        address base,
        address quote,
        uint256 price,
        uint32 orderId,
        bool isBid,
        bool isMarket,
        bool isMaker,
        uint32 n,
        uint32 uid
    ) external nonReentrant returns (bool) {
        address orderbook = IOrderbookFactory(orderbookFactory).getBookByPair(
            base,
            quote
        );
        uint256 remaining = IOrderbook(orderbook).cancelOrder(
            isBid,
            price,
            orderId,
            msg.sender
        );
        if (isBid) {
            if (isMarket) {
                return marketBuy(base, quote, remaining, isMaker, n, uid);
            } else {
                return limitBuy(base, quote, price, remaining, isMaker, n, uid);
            }
        } else {
            if (isMarket) {
                return marketSell(base, quote, remaining, isMaker, n, uid);
            } else {
                return
                    limitSell(base, quote, price, remaining, isMaker, n, uid);
            }
        }
    }

    /**
     * @dev Returns the address of the orderbook with the given ID.
     * @param id The ID of the orderbook to retrieve.
     * @return The address of the orderbook.
     */
    function getOrderbookById(uint256 id) external view returns (address) {
        return IOrderbookFactory(orderbookFactory).getBook(id);
    }

    /**
     * @dev Returns the base and quote asset addresses for the given orderbook.
     * @param orderbook The address of the orderbook to retrieve the base and quote asset addresses for.
     * @return base The address of the base asset.
     * @return quote The address of the quote asset.
     */
    function getBaseQuote(
        address orderbook
    ) external view returns (address base, address quote) {
        return IOrderbookFactory(orderbookFactory).getBaseQuote(orderbook);
    }

    /**
     * @dev returns addresses of pairs in OrderbookFactory registry
     * @return pairs list of pairs from start to end
     */
    function getPairs(
        uint256 start,
        uint256 end
    ) external view returns (IOrderbookFactory.Pair[] memory pairs) {
        return IOrderbookFactory(orderbookFactory).getPairs(start, end);
    }

    /**
     * @dev returns addresses of pairs in OrderbookFactory registry
     * @return pairs list of pairs from start to end
     */
    function getPairsWithIds(
        uint256[] memory ids
    ) external view returns (IOrderbookFactory.Pair[] memory pairs) {
        return IOrderbookFactory(orderbookFactory).getPairsWithIds(ids);
    }

    /**
     * @dev returns addresses of pairs in OrderbookFactory registry
     * @return names list of pair names from start to end
     */
    function getPairNames(
        uint256 start,
        uint256 end
    ) external view returns (string[] memory names) {
        return IOrderbookFactory(orderbookFactory).getPairNames(start, end);
    }

    /**
     * @dev returns addresses of pairs in OrderbookFactory registry
     * @return names list of pair names from start to end
     */
    function getPairNamesWithIds(
        uint256[] memory ids
    ) external view returns (string[] memory names) {
        return IOrderbookFactory(orderbookFactory).getPairNamesWithIds(ids);
    }

    /**
     * @dev returns addresses of pairs in OrderbookFactory registry
     * @return mktPrices list of mktPrices from start to end
     */
    function getMktPrices(
        uint256 start,
        uint256 end
    ) external view returns (uint256[] memory mktPrices) {
        IOrderbookFactory.Pair[] memory pairs = IOrderbookFactory(
            orderbookFactory
        ).getPairs(start, end);
        mktPrices = new uint256[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            try this.mktPrice(pairs[i].base, pairs[i].quote) returns (
                uint256 price
            ) {
                uint256 p = price;
                mktPrices[i] = p;
            } catch {
                uint256 p = 0;
                mktPrices[i] = p;
            }
        }
        return mktPrices;
    }

    /**
     * @dev returns addresses of pairs in OrderbookFactory registry
     * @return mktPrices list of mktPrices from start to end
     */
    function getMktPricesWithIds(
        uint256[] memory ids
    ) external view returns (uint256[] memory mktPrices) {
        IOrderbookFactory.Pair[] memory pairs = IOrderbookFactory(
            orderbookFactory
        ).getPairsWithIds(ids);
        mktPrices = new uint256[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            try this.mktPrice(pairs[i].base, pairs[i].quote) returns (
                uint256 price
            ) {
                uint256 p = price;
                mktPrices[i] = p;
            } catch {
                uint256 p = 0;
                mktPrices[i] = p;
            }
        }
        return mktPrices;
    }

    /**
     * @dev Returns prices in the ask/bid orderbook for the given trading pair.
     * @param base The address of the base asset for the trading pair.
     * @param quote The address of the quote asset for the trading pair.
     * @param isBid Boolean indicating if the orderbook to retrieve prices from is an ask orderbook.
     * @param n The number of prices to retrieve.
     */
    function getPrices(
        address base,
        address quote,
        bool isBid,
        uint32 n
    ) external view returns (uint256[] memory) {
        address orderbook = getBookByPair(base, quote);
        return IOrderbook(orderbook).getPrices(isBid, n);
    }

    /**
     * @dev Returns orders in the ask/bid orderbook for the given trading pair in a price.
     * @param base The address of the base asset for the trading pair.
     * @param quote The address of the quote asset for the trading pair.
     * @param isBid Boolean indicating if the orderbook to retrieve orders from is an ask orderbook.
     * @param price The price to retrieve orders from.
     * @param n The number of orders to retrieve.
     */
    function getOrders(
        address base,
        address quote,
        bool isBid,
        uint256 price,
        uint32 n
    ) external view returns (ExchangeOrderbook.Order[] memory) {
        address orderbook = getBookByPair(base, quote);
        return IOrderbook(orderbook).getOrders(isBid, price, n);
    }

    /**
     * @dev Returns an order in the ask/bid orderbook for the given trading pair with order id.
     * @param base The address of the base asset for the trading pair.
     * @param quote The address of the quote asset for the trading pair.
     * @param isBid Boolean indicating if the orderbook to retrieve orders from is an ask orderbook.
     * @param orderId The order id to retrieve.
     */
    function getOrder(
        address base,
        address quote,
        bool isBid,
        uint32 orderId
    ) external view returns (ExchangeOrderbook.Order memory) {
        address orderbook = getBookByPair(base, quote);
        return IOrderbook(orderbook).getOrder(isBid, orderId);
    }

    /**
     * @dev Returns order ids in the ask/bid orderbook for the given trading pair in a price.
     * @param base The address of the base asset for the trading pair.
     * @param quote The address of the quote asset for the trading pair.
     * @param isBid Boolean indicating if the orderbook to retrieve orders from is an ask orderbook.
     * @param price The price to retrieve orders from.
     * @param n The number of order ids to retrieve.
     */
    function getOrderIds(
        address base,
        address quote,
        bool isBid,
        uint256 price,
        uint32 n
    ) external view returns (uint32[] memory) {
        address orderbook = getBookByPair(base, quote);
        return IOrderbook(orderbook).getOrderIds(isBid, price, n);
    }

    /**
     * @dev Returns the address of the orderbook for the given base and quote asset addresses.
     * @param base The address of the base asset for the trading pair.
     * @param quote The address of the quote asset for the trading pair.
     * @return book The address of the orderbook.
     */
    function getBookByPair(
        address base,
        address quote
    ) public view returns (address book) {
        return IOrderbookFactory(orderbookFactory).getBookByPair(base, quote);
    }

    function heads(
        address base,
        address quote
    ) external view returns (uint256 bidHead, uint256 askHead) {
        address orderbook = getBookByPair(base, quote);
        return IOrderbook(orderbook).heads();
    }

    function mktPrice(
        address base,
        address quote
    ) public view returns (uint256) {
        address orderbook = getBookByPair(base, quote);
        return IOrderbook(orderbook).mktPrice();
    }

    /**
     * @dev return converted amount from base to quote or vice versa
     * @param base address of base asset
     * @param quote address of quote asset
     * @param amount amount of base or quote asset
     * @param isBid if true, amount is quote asset, otherwise base asset
     * @return converted converted amount from base to quote or vice versa.
     * if true, amount is quote asset, otherwise base asset
     * if orderbook does not exist, return 0
     */
    function convert(
        address base,
        address quote,
        uint256 amount,
        bool isBid
    ) public view returns (uint256 converted) {
        address orderbook = getBookByPair(base, quote);
        if (base == quote) {
            return amount;
        } else if (orderbook == address(0)) {
            return 0;
        } else {
            return IOrderbook(orderbook).assetValue(amount, isBid);
        }
    }

    /**
     * @dev Internal function which makes an order on the orderbook.
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @param orderbook The address of the orderbook contract for the trading pair
     * @param withoutFee The remaining amount of the asset after the market order has been executed
     * @param price The price, base/quote regardless of decimals of the assets in the pair represented with 8 decimals (if 1000, base is 1000x quote)
     * @param isBid Boolean indicating if the order is a buy (false) or a sell (true)
     */
    function _makeOrder(
        address base,
        address quote,
        address orderbook,
        uint256 withoutFee,
        uint256 price,
        bool isBid
    ) internal {
        uint32 id;
        // create order
        if (isBid) {
            id = IOrderbook(orderbook).placeBid(msg.sender, price, withoutFee);
        } else {
            id = IOrderbook(orderbook).placeAsk(msg.sender, price, withoutFee);
        }
        emit OrderPlaced(base, quote, isBid, id);
    }

    /**
     * @dev Match bid if `isBid` is true, match ask if `isBid` is false.
     */
    function _matchAt(
        address orderbook,
        address give,
        bool isBid,
        uint256 amount,
        uint256 price,
        uint32 i,
        uint32 n
    ) internal returns (uint256 remaining, uint32 k) {
        if (n > 20) {
            revert TooManyMatches(n);
        }
        remaining = amount;
        while (
            remaining > 0 &&
            !IOrderbook(orderbook).isEmpty(!isBid, price) &&
            i < n
        ) {
            // fpop OrderLinkedList by price, if ask you get bid order, if bid you get ask order. Get quote asset on bid order on buy, base asset on ask order on sell
            (uint32 orderId, uint256 required) = IOrderbook(orderbook).fpop(
                !isBid,
                price,
                remaining
            );
            // order exists, and amount is not 0
            if (remaining <= required) {
                // set last matching price
                IOrderbook(orderbook).setLmp(price);
                // execute order
                TransferHelper.safeTransfer(give, orderbook, remaining);
                address owner = IOrderbook(orderbook).execute(
                    orderId,
                    !isBid,
                    price,
                    msg.sender,
                    remaining
                );
                // emit event order matched
                emit OrderMatched(
                    orderbook,
                    orderId,
                    isBid,
                    msg.sender,
                    owner,
                    remaining,
                    price
                );
                // end loop as remaining is 0
                return (0, n);
            }
            // order is null
            else if (required == 0) {
                ++i;
                continue;
            }
            // remaining >= depositAmount
            else {
                remaining -= required;
                TransferHelper.safeTransfer(give, orderbook, required);
                address owner = IOrderbook(orderbook).execute(
                    orderId,
                    !isBid,
                    price,
                    msg.sender,
                    required
                );
                // emit event order matched
                emit OrderMatched(
                    orderbook,
                    orderId,
                    isBid,
                    msg.sender,
                    owner,
                    required,
                    price
                );
                ++i;
            }
        }
        k = i;
        return (remaining, k);
    }

    /**
     * @dev Executes limit order by matching orders in the orderbook based on the provided limit price.
     * @param orderbook The address of the orderbook to execute the limit order on.
     * @param amount The amount of asset to trade.
     * @param give The address of the asset to be traded.
     * @param isBid True if the order is an ask (sell) order, false if it is a bid (buy) order.
     * @param limitPrice The maximum price at which the order can be executed.
     * @param n The maximum number of matches to execute.
     * @return remaining The remaining amount of asset that was not traded.
     */
    function _limitOrder(
        address orderbook,
        uint256 amount,
        address give,
        bool isBid,
        uint256 limitPrice,
        uint32 n
    ) internal returns (uint256 remaining, uint256 lmp) {
        remaining = amount;
        lmp = 0;
        uint32 i = 0;
        if (isBid) {
            // check if there is any matching ask order until matching ask order price is lower than the limit bid Price
            uint256 askHead = IOrderbook(orderbook).askHead();
            while (
                remaining > 0 && askHead != 0 && askHead <= limitPrice && i < n
            ) {
                lmp = askHead;
                (remaining, i) = _matchAt(
                    orderbook,
                    give,
                    isBid,
                    remaining,
                    askHead,
                    i,
                    n
                );
                askHead = IOrderbook(orderbook).askHead();
            }
        } else {
            // check if there is any maching bid order until matching bid order price is higher than the limit ask price
            uint256 bidHead = IOrderbook(orderbook).bidHead();
            while (
                remaining > 0 && bidHead != 0 && bidHead >= limitPrice && i < n
            ) {
                lmp = bidHead;
                (remaining, i) = _matchAt(
                    orderbook,
                    give,
                    isBid,
                    remaining,
                    bidHead,
                    i,
                    n
                );
                bidHead = IOrderbook(orderbook).bidHead();
            }
        }
        // set last match price
        if (lmp != 0) {
            IOrderbook(orderbook).setLmp(lmp);
        }
        return (remaining, lmp);
    }

    /**
     * @dev Determines if an order can be made at the market price,
     * and if so, makes the an order on the orderbook.
     * If an order cannot be made, transfers the remaining asset to either the orderbook or the user.
     * @param base The address of the base asset for the trading pair
     * @param quote The address of the quote asset for the trading pair
     * @param orderbook The address of the orderbook contract for the trading pair
     * @param remaining The remaining amount of the asset after the market order has been taken
     * @param price The price used to determine if an order can be made
     * @param isBid Boolean indicating if the order was a buy (true) or a sell (false)
     * @param isMaker Boolean indicating if an order is for storing in orderbook
     */
    function _detMake(
        address base,
        address quote,
        address orderbook,
        uint256 remaining,
        uint256 price,
        bool isBid,
        bool isMaker
    ) internal {
        if (remaining > 0) {
            address stopTo = isMaker ? orderbook : msg.sender;
            TransferHelper.safeTransfer(
                isBid ? quote : base,
                stopTo,
                remaining
            );
            if (isMaker)
                _makeOrder(base, quote, orderbook, remaining, price, isBid);
        }
    }

    /**
     * @dev Deposit amount of asset to the contract with the given asset information and subtracts the fee.
     * @param base The address of the base asset.
     * @param quote The address of the quote asset.
     * @param amount The amount of asset to deposit.
     * @param isBid Whether it is an ask order or not.
     * If ask, the quote asset is transferred to the contract.
     * @return withoutFee The amount of asset without the fee.
     * @return book The address of the orderbook for the given asset pair.
     */
    function _deposit(
        address base,
        address quote,
        uint256 price,
        uint256 amount,
        bool isBid,
        uint32 uid,
        bool isMaker
    ) internal returns (uint256 withoutFee, address book) {
        // get orderbook address from the base and quote asset
        book = getBookByPair(base, quote);
        if (book == address(0)) {
            book = addPair(base, quote);
        }
        // check if amount is valid in case of both market and limit
        uint256 converted = _convert(book, price, amount, !isBid);
        if (converted == 0) {
            revert OrderSizeTooSmall(
                amount,
                _convert(book, price, 1, isBid)
            );
        }
        // check if sender has uid
        uint256 fee = _fee(base, quote, amount, isBid, uid, isMaker);
        withoutFee = amount - fee;
        if (isBid) {
            // transfer input asset give user to this contract
            if (quote != WETH) {
                TransferHelper.safeTransferFrom(
                    quote,
                    msg.sender,
                    address(this),
                    amount
                );
            }
            TransferHelper.safeTransfer(quote, feeTo, fee);
        } else {
            // transfer input asset give user to this contract
            if (base != WETH) {
                TransferHelper.safeTransferFrom(
                    base,
                    msg.sender,
                    address(this),
                    amount
                );
            }
            TransferHelper.safeTransfer(base, feeTo, fee);
        }

        return (withoutFee, book);
    }

    function _fee(
        address base,
        address quote,
        uint256 amount,
        bool isBid,
        uint32 uid,
        bool isMaker
    ) internal returns (uint256 fee) {
        if (uid != 0 && IRevenue(feeTo).isReportable(msg.sender, uid)) {
            uint32 feeNum = IRevenue(feeTo).feeOf(uid, isMaker);
            // report fee to accountant
            IRevenue(feeTo).report(
                uid,
                isBid ? quote : base,
                amount,
                true
            );
            return (amount * feeNum) / feeDenom;
        } else {
            return amount / 1000;
        }
    }

    /**
     * @dev return converted amount from base to quote or vice versa
     * @param orderbook address of orderbook
     * @param price price of base/quote regardless of decimals of the assets in the pair represented with 8 decimals (if 1000, base is 1000x quote) proposed by a trader
     * @param amount amount of base or quote asset
     * @param isBid if true, amount is quote asset, otherwise base asset
     * @return converted converted amount from base to quote or vice versa.
     * if true, amount is quote asset, otherwise base asset
     * if orderbook does not exist, return 0
     */
    function _convert(
        address orderbook,
        uint256 price,
        uint256 amount,
        bool isBid
    ) internal view returns (uint256 converted) {
        if (orderbook == address(0)) {
            return 0;
        } else {
            return price == 0 ? IOrderbook(orderbook).assetValue(amount, isBid) : IOrderbook(orderbook).convert(price, amount, isBid);
        }
    }
}