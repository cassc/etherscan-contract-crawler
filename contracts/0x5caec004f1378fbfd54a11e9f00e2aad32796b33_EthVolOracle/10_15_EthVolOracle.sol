// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {ISqueethController} from "./interfaces/ISqueethController.sol";
import {IUniswapV3Pool} from "./interfaces/IUniswapV3Pool.sol";
import {IERC20} from "./interfaces/IERC20.sol";

import {OracleLibrary} from "./libraries/OracleLibrary.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

contract EthVolOracle {
    using FixedPointMathLib for uint256;

    /// @dev squeeth controller address
    ISqueethController public immutable squeethController;

    address public immutable squeethPool;
    address public immutable wethPool;

    address public immutable weth;
    address public immutable squeeth;
    address public immutable usdc;

    uint256 private constant multiplier = uint256((uint256(365) * 1e19) / 175); // 365 / 17.5

    constructor(address _squeethController) {
        ISqueethController controller = ISqueethController(_squeethController);

        // set pools
        squeethPool = controller.wPowerPerpPool();
        wethPool = controller.ethQuoteCurrencyPool();

        weth = controller.weth();
        squeeth = controller.wPowerPerp();
        usdc = controller.quoteCurrency();

        squeethController = controller;
    }

    /**
     * @notice  get the time-weighted vol from squeeth pool
     * @dev     implied vol = √((implied daily funding) * 365)
     * @param   secondsAgo number of seconds in the past to start calculating time-weighted average
     * @return  impliedVol scaled by 1e18. (1e18 = 100%)
     */
    function getEthTwaIV(uint32 secondsAgo)
        external
        view
        returns (uint256 impliedVol)
    {
        uint256 squeethEth = _fetchSqueethTwap(secondsAgo);
        uint256 ethUsd = _fetchEthTwap(secondsAgo);
        if (ethUsd > squeethEth) return 0;
        // √ implied funding * 365
        // = √ (ln(mark / index) / 17.5 * 365)
        // = √ (ln(mark / index) * 20.85714 )
        impliedVol = (squeethEth.divWadDown(ethUsd).ln() * multiplier).sqrt();
    }

    /**
     * @notice  get the implied funding
     * @dev     implied funding = ln(mark / index) / funding period
     * @param   secondsAgo number of seconds in the past to start calculating time-weighted average
     * @return  impliedFunding scaled by 1e18. (1e18 = 100%)
     */
    function getImpliedFunding(uint32 secondsAgo)
        public
        view
        returns (uint256 impliedFunding)
    {
        uint256 squeethEth = _fetchSqueethTwap(secondsAgo);
        uint256 ethUsd = _fetchEthTwap(secondsAgo);
        if (ethUsd > squeethEth || ethUsd == 0) return 0;
        impliedFunding = ((squeethEth.divWadDown(ethUsd).ln()) * 10) / 175;
    }

    /**
     * @notice  get the twap for squeeth / eth
     * @dev     squeeth price = (osqueeth pool price) / normFactor * 1e4
     * @param   secondsAgo number of seconds in the past to start calculating time-weighted average
     * @return  price scaled by 1e18
     */
    function fetchSqueethTwap(uint32 secondsAgo)
        external
        view
        returns (uint256)
    {
        return _fetchSqueethTwap(secondsAgo);
    }

    /**
     * @notice  get the twap for eth / usdc from uniswap pool directly
     * @param   secondsAgo number of seconds in the past to start calculating time-weighted average
     * @return  price scaled by 1e18
     */
    function fetchEthTwap(uint32 secondsAgo) external view returns (uint256) {
        return _fetchEthTwap(secondsAgo);
    }

    /**
     * @notice  get the twap for squeeth / eth
     * @dev     squeeth price = (osqueeth pool price) / normFactor * 1e4
     * @param   secondsAgo number of seconds in the past to start calculating time-weighted average
     * @return  price scaled by 1e18
     */
    function _fetchSqueethTwap(uint32 secondsAgo)
        internal
        view
        returns (uint256)
    {
        uint256 wsqueethPrice = _fetchRawTwap(
            squeethPool,
            squeeth,
            weth,
            1e22, // 1e18 * 1e4 (squeeth scale)
            secondsAgo
        );

        uint256 normFactor = squeethController.normalizationFactor();

        // return directly becauase squeeth and weth has same decimals
        return wsqueethPrice.divWadDown(normFactor);
    }

    /**
     * @notice  get the twap for eth / usdc from uniswap pool directly
     * @param   secondsAgo number of seconds in the past to start calculating time-weighted average
     * @return  price scaled by 1e18
     */
    function _fetchEthTwap(uint32 secondsAgo)
        internal
        view
        returns (uint256 price)
    {
        price = _fetchRawTwap(
            wethPool,
            weth,
            usdc,
            1e30, // 1e18 + 1e12 (decimals diff)
            secondsAgo
        );
    }

    /**
     * @notice get raw twap from the uniswap pool
     * @dev if period is longer than the current timestamp - first timestamp stored in the pool, this will revert with "OLD".
     * @param pool uniswap pool address
     * @param base base currency.
     * @param quote quote currency.
     * @param secondsAgo number of seconds in the past to start calculating time-weighted average
     * @param amountIn amount of base currency provided
     * @return amountOut of quote currency to receive
     */
    function _fetchRawTwap(
        address pool,
        address base,
        address quote,
        uint128 amountIn,
        uint32 secondsAgo
    ) internal view returns (uint256) {
        int24 twapTick = OracleLibrary.consultArithmeticMeanTick(
            pool,
            secondsAgo
        );
        return OracleLibrary.getQuoteAtTick(twapTick, amountIn, base, quote);
    }
}