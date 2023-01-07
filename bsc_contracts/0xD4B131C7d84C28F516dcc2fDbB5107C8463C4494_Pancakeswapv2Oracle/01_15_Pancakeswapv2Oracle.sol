// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {PriceLibrary as Prices} from "../libs/BscPriceLibrary.sol";
import "../libs/FixedPoint.sol";
import "../recipe/PancakeswapV2Library.sol";
import "../interfaces/IUsdcOracle.sol";

contract Pancakeswapv2Oracle is IUsdcOracle, AccessControl {
    /* ==========  Libraries  ========== */

    using Prices for address;
    using Prices for Prices.PriceObservation;
    using Prices for Prices.TwoWayAveragePrice;
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    /* ==========  Constants  ========== */

    // Period over which prices are observed, each period should have 1 price observation.
    // Minimum time elapsed between price observations
    uint32 public immutable MINIMUM_OBSERVATION_DELAY;

    address public immutable USDC; // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable uniswapFactory; // 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    uint32 public immutable maxObservationAge;

    /* ==========  Storage  ========== */

    uint32 public observationPeriod;
    // Price observations for tokens indexed by time period.
    mapping(address => mapping(uint256 => Prices.PriceObservation)) internal priceObservations;

    /* ==========  Events  ========== */

    event PriceUpdated(
        address indexed token,
        uint224 tokenPriceCumulativeLast,
        uint224 ethPriceCumulativeLast
    );

    /* ==========  Constructor  ========== */

    constructor(address _uniswapFactory, uint32 _initialObservationPeriod, address _usdc, address _weth) {
        require(_uniswapFactory != address(0), "ERR_UNISWAPV2_FACTORY_INIT");
        require(_weth!= address(0), "ERR_WETH_INIT");
        uniswapFactory = _uniswapFactory;
        USDC = _usdc;
        WETH = _weth;
        observationPeriod = _initialObservationPeriod;
        MINIMUM_OBSERVATION_DELAY = _initialObservationPeriod / 2;
        maxObservationAge = _initialObservationPeriod * 2;
    }

    /* ==========  External Functions  ========== */

    function getLastPriceObservation(address token)
        external
        view
        returns (Prices.PriceObservation memory)
    {
        Prices.PriceObservation memory current = Prices.observeTwoWayPrice(
            uniswapFactory,
            token,
            WETH
        );
        Prices.PriceObservation memory previous = _getLatestUsableObservation(
            token,
            current.timestamp
        );
        return previous;
    }

    /**
     * @dev Gets the price observation at `observationIndex` for `token`.
     *
     * Note: This does not assert that there is an observation for that index,
     * this should be verified by the recipient.
     */
    function getPriceObservation(address token, uint256 observationIndex)
        external
        view
        returns (Prices.PriceObservation memory)
    {
        return priceObservations[token][observationIndex];
    }

    function canUpdatePrice(address token) external view returns (bool) {
        Prices.PriceObservation memory newObservation = Prices
            .observeTwoWayPrice(uniswapFactory, token, WETH);
        // We use the observation's timestamp rather than `now` because the
        // UniSwap pair may not have updated the price this block.
        uint256 observationIndex = observationIndexOf(newObservation.timestamp);
        // If this period already has an observation, return false.
        if (priceObservations[token][observationIndex].timestamp != 0)
            return false;
        // An observation can be made if the last update was at least half a period ago.
        uint32 timeElapsed = newObservation.timestamp -
            priceObservations[token][observationIndex - 1].timestamp;
        return timeElapsed >= MINIMUM_OBSERVATION_DELAY;
    }

    /**
     * @dev Returns the TwoWayAveragePrice structs representing the average price of
     * weth in terms of each token in `tokens` and the average price of each token
     * in terms of weth.
     *
     * Note: Requires that the token has a price observation between 0.5
     * and 2 periods old.
     */
    function computeTwoWayAveragePrices(address[] memory tokens)
        external
        view
        returns (Prices.TwoWayAveragePrice[] memory averagePrices, uint256 earliestTimestamp)
    {
        uint256 len = tokens.length;
        averagePrices = new Prices.TwoWayAveragePrice[](len);
        uint256 timestamp;
        for (uint256 i = 0; i < len; i++) {
            (averagePrices[i], timestamp) = computeTwoWayAveragePrice(tokens[i]);
            if (timestamp < earliestTimestamp) {
                earliestTimestamp = timestamp;
            }
        }
    }

    function canUpdateTokenPrices() external pure override returns (bool) {
        return true;
    }

    /**
     * @dev Updates the prices of multiple tokens.
     *
     * @return updates Array of boolean values indicating which tokens
     * successfully updated their prices.
     */
    function updateTokenPrices(address[] memory tokens)
        external
        returns (bool[] memory updates)
    {
        updateWethPrice();
        updates = new bool[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            updates[i] = updatePrice(tokens[i]);
        }
    }

    function tokenETHValue(address tokenIn, uint256 amount)
        external
        view
        returns (uint256, uint256)
    {
        if (tokenIn == WETH) {
            return (amount, block.timestamp);
        }

        return computeAverageAmountIn(tokenIn, amount);
    }

    /**
     * @dev Returns the UQ112x112 structs representing the average price of
     * weth in terms of each token in `tokens`.
     */
    function computeAverageEthPrices(address[] memory tokens)
        external
        view
        returns (FixedPoint.uq112x112[] memory averagePrices, uint256 earliestTimestamp)
    {
        uint256 len = tokens.length;
        averagePrices = new FixedPoint.uq112x112[](len);
        uint256 timestamp;
        for (uint256 i = 0; i < len; i++) {
            (averagePrices[i], timestamp) = computeAverageEthPrice(tokens[i]);
            if (timestamp < earliestTimestamp) {
                earliestTimestamp = timestamp;
            }
        }
    }

    /* ==========  Public  Functions  ========== */

    /*
     * @dev Updates the latest price observation for a token if allowable.
     *
     * Note: The price can only be updated once per period, and price
     * observations must be made at least half a period apart.
     *
     * @param token Token to update the price of
     * @return didUpdate Whether the token price was updated.
     */
    // update weth price in usdc
    function updateWethPrice() public returns (bool) {
        Prices.PriceObservation memory newObservation = Prices
            .observeTwoWayPrice(uniswapFactory, WETH, USDC);
        // We use the observation's timestamp rather than `now` because the
        // UniSwap pair may not have updated the price this block.
        uint256 observationIndex = observationIndexOf(newObservation.timestamp);

        Prices.PriceObservation storage current = priceObservations[WETH][
            observationIndex
        ];
        if (current.timestamp != 0) {
            // If an observation has already been made for this period, do not update.
            return false;
        }

        Prices.PriceObservation memory previous = priceObservations[WETH][
            observationIndex - 1
        ];
        uint256 timeElapsed = newObservation.timestamp - previous.timestamp;
        if (timeElapsed < MINIMUM_OBSERVATION_DELAY) {
            // If less than half a period has passed since the previous observation, do not update.
            return false;
        }
        priceObservations[WETH][observationIndex] = newObservation;
        emit PriceUpdated(
            WETH,
            newObservation.priceCumulativeLast,
            newObservation.ethPriceCumulativeLast
        );
        return true;
    }

    function updatePrice(address token) public returns (bool) {
        if (token == WETH) return true;

        Prices.PriceObservation memory newObservation = Prices
            .observeTwoWayPrice(uniswapFactory, token, WETH);
        // We use the observation's timestamp rather than `now` because the
        // UniSwap pair may not have updated the price this block.
        uint256 observationIndex = observationIndexOf(newObservation.timestamp);

        Prices.PriceObservation storage current = priceObservations[token][
            observationIndex
        ];
        if (current.timestamp != 0) {
            // If an observation has already been made for this period, do not update.
            return false;
        }

        Prices.PriceObservation memory previous = priceObservations[token][
            observationIndex - 1
        ];
        uint256 timeElapsed = newObservation.timestamp - previous.timestamp;
        if (timeElapsed < MINIMUM_OBSERVATION_DELAY) {
            // If less than half a period has passed since the previous observation, do not update.
            return false;
        }
        priceObservations[token][observationIndex] = newObservation;

        emit PriceUpdated(
            token,
            newObservation.priceCumulativeLast,
            newObservation.ethPriceCumulativeLast
        );
        return true;
    }

    /**
     * @dev Gets the observation index for `timestamp`
     */
    function observationIndexOf(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        return timestamp / observationPeriod;
    }

    /**
     * @dev Computes the average value in weth of `amountIn` of `token`.
     */
    function computeAverageAmountOut(
        address token,
        address referenceToken,
        uint256 amountIn
    ) public view returns (uint144 amountOut, uint256 timestamp) {
        require(token != USDC, "ERR_INVALID_TOKEN");
        if (token == WETH) {
            require(referenceToken == USDC, "INCORRECT_REFERENCET");
        } else {
            require(referenceToken == WETH, "INCORRECT_REFERENCET");
        }
        FixedPoint.uq112x112 memory priceAverage;
        (priceAverage, timestamp) = computeAverageTokenPrice(token, referenceToken);
        return (priceAverage.mul(amountIn).decode144(), timestamp);
    }

    /**
     * @dev Computes the average value in `token` of `amountOut` of weth.
     */
    function computeAverageAmountIn(address token, uint256 amountOut)
        public
        view
        returns (uint144 amountIn, uint256 timestamp)
    {
        FixedPoint.uq112x112 memory priceAverage;
        (priceAverage,timestamp) = computeAverageEthPrice(token);
        return (priceAverage.mul(amountOut).decode144(), timestamp);
    }

    function tokenUsdcValue(address tokenIn, uint256 amount)
        public
        view
        override
        returns (uint256, uint256)
    {
        if (tokenIn == USDC) {
            return (amount, block.timestamp);
        }
        return getPrice(tokenIn, USDC, amount);
    }

    function getPrice(address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint8 decimals = IERC20Metadata(base).decimals();
        uint256 amount = 10 ** decimals;
        return getPrice(base, quote, amount);
    }

    function getPrice(address base, address quote, uint256 amount)
        public
        view
        returns (uint256, uint256)
    {
        if (base == WETH) {
            return computeAverageAmountOut(base, quote, amount);
        }
        // tokenWETHValue is number of eth we will get for _amount amount of _tokenIn.
        (uint256 tokenWETHValue, uint256 timestamp1) = computeAverageAmountOut(
            base,
            WETH,
            amount
        );

        //  WETHUsdValue is numver of usdc for tokenWETHValue amount of WETH.
        (uint256 WETHquoteValue, uint256 timestamp2) = computeAverageAmountOut(
            WETH,
            quote,
            tokenWETHValue
        );
        uint256 earliestTimestamp = (timestamp1 < timestamp2) ? timestamp1 : timestamp2;
        return (WETHquoteValue, earliestTimestamp);
    }

    /**
     * @dev Returns the UQ112x112 struct representing the average price of
     * `token` in terms of usdc.
     *
     * Note: Requires that the token has a price observation between 0.5
     * and 2 periods old.
     */
    function computeAverageTokenPrice(address token, address referenceToken)
        public
        view
        returns (FixedPoint.uq112x112 memory priceAverage, uint256 timestamp)
    {
        require(token != USDC, "ERR_INVALID_TOKEN");
        if (token == WETH) {
            require(referenceToken == USDC, "INCORRECT_REFERENCET");
        } else {
            require(referenceToken == WETH, "INCORRECT_REFERENCET");
        }
        // Get the current cumulative price
        Prices.PriceObservation memory current = Prices.observeTwoWayPrice(
            uniswapFactory,
            token,
            referenceToken
        );
        // Get the latest usable price
        Prices.PriceObservation memory previous = _getLatestUsableObservation(
            token,
            current.timestamp
        );

        return (previous.computeAverageTokenPrice(current), previous.timestamp);
    }

    /**
     * @dev Returns the UQ112x112 struct representing the average price of
     * weth in terms of `token`.
     *
     * Note: Requires that the token has a price observation between 0.5
     * and 2 periods old.
     */
    function computeAverageEthPrice(address token)
        public
        view
        returns (FixedPoint.uq112x112 memory priceAverage, uint256 timestamp)
    {
        // Get the current cumulative price
        Prices.PriceObservation memory current = Prices.observeTwoWayPrice(
            uniswapFactory,
            token,
            WETH
        );
        // Get the latest usable price
        Prices.PriceObservation memory previous = _getLatestUsableObservation(
            token,
            current.timestamp
        );

        return (previous.computeAverageEthPrice(current), previous.timestamp);
    }

    /**
     * @dev Returns the TwoWayAveragePrice struct representing the average price of
     * weth in terms of `token` and the average price of `token` in terms of weth.
     *
     * Note: Requires that the token has a price observation between 0.5
     * and 2 periods old.
     */
    function computeTwoWayAveragePrice(address token)
        public
        view
        returns (Prices.TwoWayAveragePrice memory, uint256 timestamp)
    {
        // Get the current cumulative price
        Prices.PriceObservation memory current = Prices.observeTwoWayPrice(
            uniswapFactory,
            token,
            WETH
        );
        // Get the latest usable price
        Prices.PriceObservation memory previous = _getLatestUsableObservation(
            token,
            current.timestamp
        );

        return (previous.computeTwoWayAveragePrice(current), previous.timestamp);
    }

    /* ==========  Internal Observation Functions  ========== */

    /**
     * @dev Gets the latest price observation which is at least half a period older
     * than `timestamp` and at most 2 periods older.
     *
     * @param token Token to get the latest price for
     * @param timestamp Reference timestamp for comparison
     */
    function _getLatestUsableObservation(address token, uint32 timestamp)
        internal
        view
        returns (Prices.PriceObservation memory observation)
    {
        uint256 observationIndex = observationIndexOf(timestamp);
        uint256 periodTimeElapsed = timestamp % observationPeriod;
        // uint256 maxAge = maxObservationAge;
        // Before looking at the current observation period, check if it is possible
        // for an observation in the current period to be more than half a period old.
        if (periodTimeElapsed >= MINIMUM_OBSERVATION_DELAY) {
            observation = priceObservations[token][observationIndex];
            if (
                observation.timestamp != 0 &&
                timestamp - observation.timestamp >= MINIMUM_OBSERVATION_DELAY
            ) {
                return observation;
            }
        }

        // Check the observation for the previous period
        observation = priceObservations[token][--observationIndex];
        uint256 timeElapsed = timestamp - observation.timestamp;
        bool usable = observation.timestamp != 0 &&
            timeElapsed >= MINIMUM_OBSERVATION_DELAY;
        while (!usable) {
            observation = priceObservations[token][--observationIndex];
            uint256 obsTime = observation.timestamp;
            timeElapsed =
                timestamp -
                (obsTime == 0 ? observationPeriod * observationIndex : obsTime);
            usable =
                observation.timestamp != 0 &&
                timeElapsed >= MINIMUM_OBSERVATION_DELAY;
            require(
                timeElapsed <= maxObservationAge,
                "ERR_USABLE_PRICE_NOT_FOUND"
            );
        }
        return observation;
    }
}