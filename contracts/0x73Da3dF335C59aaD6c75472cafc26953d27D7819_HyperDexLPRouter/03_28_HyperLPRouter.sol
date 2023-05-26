// SPDX-License-Identifier: GPL-3.0

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {GasStationBase} from "./abstract/GasStationBase.sol";
import {Ownable} from "./abstract/Ownable.sol";
import {SwapGuard} from "./abstract/SwapGuard.sol";
import {IHyperLPFactory, IHyperLPool} from "./interfaces/IHyper.sol";
import {
    IHyperLPoolFactoryStorage,
    IHyperLPoolStorage
} from "./interfaces/IHyperStorage.sol";
import {SafeERC20v2} from "./utils/SafeERC20v2.sol";
import {LiquidityAmounts} from "./vendor/uniswap/LiquidityAmounts.sol";
import {FullMath} from "./vendor/uniswap/FullMath.sol";
import {SafeCast} from "./vendor/uniswap/SafeCast.sol";
import {TickMath} from "./vendor/uniswap/TickMath.sol";

interface IERC20Meta {
    function decimals() external view returns (uint8);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract HyperLPRouter is SwapGuard, GasStationBase, Ownable, ReentrancyGuard {
    using FullMath for int8;
    using SafeERC20v2 for IERC20;
    using SafeCast for uint256;
    using TickMath for int24;

    struct SwapCallbackData {
        address tokenIn;
        address tokenOut;
        address payer;
    }

    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IHyperLPFactory public immutable lpfactory;
    IUniswapV3Factory public immutable factory;
    IWETH public immutable wETH;

    event Minted(
        address receiver,
        uint256 mintAmount,
        uint256 amount0In,
        uint256 amount1In,
        uint128 liquidityMinted
    );

    event Burned(
        address receiver,
        address hyperpool,
        uint256 burnAmount,
        address returnToken,
        uint256 returnAmount,
        uint128 liquidityBurned
    );

    constructor(address hyperlpfactory, address weth) {
        lpfactory = IHyperLPFactory(hyperlpfactory);
        factory = IUniswapV3Factory(
            IHyperLPoolFactoryStorage(hyperlpfactory).factory()
        );
        wETH = IWETH(weth);
    }

    /**
     * @notice mint fungible `hyperpool` tokens with `token` or ETH transformation
     * to `hyperpool` tokens
     * when current tick is outside of [lowerTick, upperTick]
     * @dev see HyperLPool.mint method
     * @param hyperpool HyperLPool address
     * @param paymentToken token to pay
     * @param paymentAmount amount of token to pay
     * @param sqrtPriceLimitX960 sqrtRatioX96 from uniswap pool store for paymentToken/token0 swap
     * @param sqrtPriceLimitX961 sqrtRatioX96 from uniswap pool store for paymentToken/token1 swap
     * @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
     * @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
     * @return mintAmount The number of HyperLP tokens to mint
     * @return liquidityMinted amount of liquidity added to the underlying Uniswap V3 position
     */
    // solhint-disable-next-line function-max-lines, code-complexity
    function mint(
        address hyperpool,
        address paymentToken,
        uint256 paymentAmount,
        uint160 sqrtPriceLimitX960,
        uint160 sqrtPriceLimitX961
    )
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount,
            uint128 liquidityMinted
        )
    {
        require(paymentAmount > 0, "!amount");
        require(lpfactory.isTrustedPool(hyperpool), "!pool");

        address sender = _msgSender();

        if (paymentToken == _ETH) {
            require(paymentAmount == msg.value, "!eth");
            wETH.deposit{value: paymentAmount}();
            wETH.transfer(address(this), paymentAmount); // change for gasStation usage
            paymentToken = address(wETH);
            sender = address(this);
        }

        address token0;
        address token1;

        (, , token0, token1, amount0, amount1) = getMintAmounts(
            hyperpool,
            paymentToken,
            paymentAmount
        );

        uint24 fee = IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).fee();

        if (paymentToken != token0) {
            _swap(
                paymentToken,
                token0,
                fee,
                amount0,
                sqrtPriceLimitX960,
                sender
            );
        } else if (sender != address(this)) {
            IERC20(paymentToken).safeTransferFrom(
                sender,
                address(this),
                amount0
            );
        }

        if (paymentToken != token1) {
            _swap(
                paymentToken,
                token1,
                fee,
                amount1,
                sqrtPriceLimitX961,
                sender
            );
        } else if (sender != address(this)) {
            IERC20(paymentToken).safeTransferFrom(
                sender,
                address(this),
                amount1
            );
        }

        amount0 = IERC20(token0).balanceOf(address(this));
        amount1 = IERC20(token1).balanceOf(address(this));

        IERC20(token0).approve(hyperpool, amount0);
        IERC20(token1).approve(hyperpool, amount1);

        (amount0, amount1, mintAmount, liquidityMinted) = IHyperLPool(hyperpool)
            .mint(amount0, amount1, _msgSender());

        emit Minted(
            _msgSender(),
            mintAmount,
            amount0,
            amount1,
            liquidityMinted
        );

        amount0 = IERC20(token0).balanceOf(address(this));
        amount1 = IERC20(token1).balanceOf(address(this));

        if (amount0 > 0) {
            IERC20(token0).safeTransfer(_msgSender(), amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).safeTransfer(_msgSender(), amount1);
        }
    }

    /**
     * @notice burn fungible `hyperpool` tokens and swap them to returnToken
     * @dev see HyperLPool.burn method
     * @param hyperpool HyperLPool address
     * @param burnAmount amount of LP token to burn
     * @param returnToken token to withdraw
     * @param sqrtPriceLimitX960 sqrtRatioX96 from uniswap pool store for paymentToken/token0 swap
     * @param sqrtPriceLimitX961 sqrtRatioX96 from uniswap pool store for paymentToken/token1 swap
     * @return returnAmount amount of returnToken transferred to msg.sender by burn `burnAmount`
     * @return liquidityBurned amount of liquidity removed from the underlying Uniswap V3 position
     */
    // solhint-disable-next-line function-max-lines, code-complexity
    function burn(
        address hyperpool,
        uint256 burnAmount,
        address returnToken,
        uint160 sqrtPriceLimitX960,
        uint160 sqrtPriceLimitX961
    ) external returns (uint256 returnAmount, uint128 liquidityBurned) {
        require(burnAmount > 0, "!amount");
        require(lpfactory.isTrustedPool(hyperpool), "!pool");

        address sender = _msgSender();

        IERC20(hyperpool).safeTransferFrom(sender, address(this), burnAmount);

        (, , liquidityBurned) = IHyperLPool(hyperpool).burn(
            burnAmount,
            address(this)
        );

        uint24 fee = IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).fee();

        {
            IERC20 token0 = IHyperLPoolStorage(hyperpool).token0();
            uint256 amount0 = token0.balanceOf(address(this));

            if (returnToken != address(token0) && amount0 > 0) {
                amount0 = _swap(
                    address(token0),
                    returnToken,
                    fee,
                    amount0,
                    sqrtPriceLimitX960,
                    address(this)
                );
            }
        }

        {
            IERC20 token1 = IHyperLPoolStorage(hyperpool).token1();
            uint256 amount1 = token1.balanceOf(address(this));

            if (returnToken != address(token1) && amount1 > 0) {
                amount1 = _swap(
                    address(token1),
                    returnToken,
                    fee,
                    amount1,
                    sqrtPriceLimitX961,
                    address(this)
                );
            }
        }

        returnAmount = IERC20(returnToken).balanceOf(address(this));
        require(returnAmount > 0, "!balance");

        IERC20(returnToken).safeTransfer(sender, returnAmount);

        emit Burned(
            sender,
            hyperpool,
            burnAmount,
            returnToken,
            returnAmount,
            liquidityBurned
        );
    }

    /**
     * @notice Estimates burn return amount in `returnToken` token
     * @param hyperpool HyperPool address
     * @param burnAmount Burn amount of HyperPool tokens
     * @param returnToken Return token address
     * @param sqrtPriceX960 SqrtPriceX96 for hpPool.token0 => returnToken swap.
     * Used uniV3-pool(token0/returnToken).slot0.sqrtPriceX96 if 0
     * @param sqrtPriceX961 SqrtPriceX96 for hpPool.token1 => returnToken swap.
     * Used uniV3-pool(token1/returnToken).slot0.sqrtPriceX96 if 0
     * @return returnTokenReturn Return return amount  of returnToken
     * @return token0Return Pool return amount of token0
     * @return token1Return Pool return amount of token1
     */
    // solhint-disable-next-line function-max-lines
    function estimateBurnReturn(
        address hyperpool,
        uint256 burnAmount,
        address returnToken,
        uint160 sqrtPriceX960,
        uint160 sqrtPriceX961
    )
        external
        view
        returns (
            uint256 returnTokenReturn,
            uint256 token0Return,
            uint256 token1Return
        )
    {
        IUniswapV3Pool uniPool =
            IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool());
        {
            IHyperLPoolStorage hpPool = IHyperLPoolStorage(hyperpool);
            int24 lowerTick = hpPool.lowerTick();
            int24 upperTick = hpPool.upperTick();
            (uint128 liquidity, , , , ) =
                uniPool.positions(
                    keccak256(abi.encodePacked(hyperpool, lowerTick, upperTick))
                );
            liquidity = ((liquidity * burnAmount) /
                IERC20(hyperpool).totalSupply())
                .toUint128();
            (uint160 sqrtPriceX96, , , , , , ) = uniPool.slot0();
            (token0Return, token1Return) = LiquidityAmounts
                .getAmountsForLiquidity(
                sqrtPriceX96,
                lowerTick.getSqrtRatioAtTick(),
                upperTick.getSqrtRatioAtTick(),
                liquidity
            );
        }

        uint24 fee = IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).fee();

        returnTokenReturn += getSwapAmount(
            uniPool.token0(),
            returnToken,
            token0Return,
            fee,
            sqrtPriceX960
        );
        returnTokenReturn += getSwapAmount(
            uniPool.token1(),
            returnToken,
            token1Return,
            fee,
            sqrtPriceX961
        );
    }

    /**
     * @notice Breaks payment token amount for efficient HyperPool deposit
     * @param hyperpool Hyperpool address
     * @param paymentToken Token address for paymentToken => token/token1 swap
     * @param paymentAmount Payment token amount for paymentToken => token/token1 swap
     * @return amount0 / amount1 Payment token amount for paymentToken => token0 / token1 swap
     * and token0 / token1 addresses
     */
    // solhint-disable-next-line function-max-lines, code-complexity
    function getMintAmounts(
        address hyperpool,
        address paymentToken,
        uint256 paymentAmount
    )
        public
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            address token0,
            address token1,
            uint256 paymentAmount0,
            uint256 paymentAmount1
        )
    {
        token0 = address(IHyperLPoolStorage(hyperpool).token0());
        token1 = address(IHyperLPoolStorage(hyperpool).token1());

        (amount0, amount1, , ) = IHyperLPool(hyperpool).getMintAmounts(
            1e18,
            1e18
        );
        uint24 fee = IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).fee();

        paymentAmount0 = getSwapAmount(token0, paymentToken, amount0, fee, 0);
        paymentAmount1 = getSwapAmount(token1, paymentToken, amount1, fee, 0);

        uint256 paymentAmountSum = paymentAmount0 + paymentAmount1;
        amount0 = (amount0 * paymentAmount) / paymentAmountSum;
        amount1 = (amount1 * paymentAmount) / paymentAmountSum;
        paymentAmount0 = (paymentAmount0 * paymentAmount) / paymentAmountSum;
        paymentAmount1 = paymentAmount - paymentAmount0;
    }

    /**
     * @notice Calculates swap output amount
     * @param tokenIn Input token address for swap
     * @param tokenOut Output token address for swap
     * @param amountIn Input token amount
     * @param uniFee UniswapV3Pool fee
     * @param sqrtPriceX96 SqrtPriceX96 for tokenIn => tokenOut swap.
     * Used uniV3-pool(tokenIn/tokenOut).slot0.sqrtPriceX96 if 0
     * @return amountOut Output amount
     */
    function getSwapAmount(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 uniFee,
        uint160 sqrtPriceX96
    ) public view returns (uint256 amountOut) {
        amountOut = amountIn;
        if (tokenIn != tokenOut) {
            amountOut *= getPrice(tokenIn, tokenOut, uniFee, sqrtPriceX96);
            amountOut /= 1e18;
        }
    }

    /**
     * @notice Gets token0 price in token1 multiplied by 1e18
     * @param tokenIn The token address for apprisal
     * @param tokenOut The token address us currency
     * @param uniFee UniswapV3Pool fee
     * @param sqrtRatioX96 sqrtRatioX96 for token0/token1 pool
     * @return Price value
     */
    function getPrice(
        address tokenIn,
        address tokenOut,
        uint24 uniFee,
        uint160 sqrtRatioX96
    ) public view returns (uint256) {
        if (tokenIn == tokenOut) return 1e18;
        if (sqrtRatioX96 == 0) {
            address pool = factory.getPool(tokenIn, tokenOut, uniFee);
            require(pool != address(0), "!swap pool");
            (sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        }
        return
            tokenIn > tokenOut
                ? FullMath.mulDiv(1e9, 2**96, sqrtRatioX96)**2
                : FullMath.mulDiv(1e9, sqrtRatioX96, 2**96)**2;
    }

    /// @notice Uniswap v3 callback fn, called back on pool.swap
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override guardSwap nonReentrant {
        // swaps entirely within 0-liquidity regions are not supported
        require(amount0Delta > 0 || amount1Delta > 0, "uni zero amount");
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (bool isExactInput, uint256 amountToPay) =
            amount0Delta > 0
                ? (data.tokenIn < data.tokenOut, uint256(amount0Delta))
                : (data.tokenOut < data.tokenIn, uint256(amount1Delta));
        // swap in/out because exact output swaps are reversed
        address paymentToken = isExactInput ? data.tokenIn : data.tokenOut;
        if (data.payer == address(this)) {
            IERC20(paymentToken).safeTransfer(_swapPool, amountToPay);
        } else {
            IERC20(paymentToken).safeTransferFrom(
                data.payer,
                _swapPool,
                amountToPay
            );
        }
    }

    /**
     * @dev Set a new trusted gas station address
     * @param _gasStation New gas station address
     */
    function setGasStation(address _gasStation) external onlyOwner {
        _setGasStation(_gasStation);
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        address payer
    ) internal returns (uint256 amountOut) {
        if (amountIn > 0) {
            address pool = factory.getPool(tokenIn, tokenOut, fee);
            require(pool != address(0), "!swap pool");
            amountOut = IERC20(tokenOut).balanceOf(address(this));
            __swap(
                pool,
                tokenIn < tokenOut,
                amountIn,
                sqrtPriceLimitX96,
                SwapCallbackData({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    payer: payer
                })
            );
            amountOut = IERC20(tokenOut).balanceOf(address(this)) - amountOut;
            require(amountOut > 0, "!swap out");
        }
    }

    function __swap(
        address pool,
        bool zeroForOne,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private doSwap(pool) returns (uint256) {
        (int256 amount0, int256 amount1) =
            IUniswapV3Pool(pool).swap(
                address(this),
                zeroForOne,
                amountIn.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (
                        zeroForOne
                            ? TickMath.MIN_SQRT_RATIO + 1
                            : TickMath.MAX_SQRT_RATIO - 1
                    )
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }
}