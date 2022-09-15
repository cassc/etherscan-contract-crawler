// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IUniswapV3Factory} from "./interfaces/IUniswapV3Factory.sol";
import {IUniswapV3PoolState} from "./interfaces/IUniswapV3PoolState.sol";
import {Bytes} from "./libraries/BytesLib.sol";
import {IFlashSwap} from "./interfaces/IFlashSwap.sol";
import "./interfaces/IWETH9.sol";

contract ETHWSwap is OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using Bytes for bytes;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant FEE_FACTOR = 1e4;

    uint256 internal constant PRICE_PRECISION = 1e12;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    ISwapRouter internal constant v3Router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    uint256 public feeRate;

    address internal feeReceiver;

    // UniswapV3 fee level
    uint24[] internal tradingFeesV3;

    // White list tokens(USDC, DAI, WBTC, USDT), ordered by TVL
    address[] public whiteListTokens;

    IFlashSwap public flash;

    event Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event FailedFlash();

    function initialize(uint256 _feeRate, address _feeReceiver) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        feeRate = _feeRate;
        feeReceiver = _feeReceiver;
        // flash = IFlashSwap(_flash);
        whiteListTokens = [
            // USDC
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            // DAI
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            // WBTC
            0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            // USDT
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        ];
        // 0.05%, 0.3%, 1%
        tradingFeesV3 = [500, 3000, 10000];
    }

    function setFlash(address _flash) external onlyOwner {
        require(_flash != address(0), "Invalid flash");
        flash = IFlashSwap(_flash);
    }

    function setFeeRate(uint256 fee) external onlyOwner {
        require(fee <= 10000, "Invalid fee rate");
        feeRate = fee;
    }

    function setFeeReceiver(address receiver) external onlyOwner {
        require(receiver != address(0), "Invalid fee receiver");
        feeReceiver = receiver;
    }

    function swapExactTokenIn(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 expiration
    ) external {
        uint256 outPutAmount;
        uint24 v3FeeLevel = getDeepestPoolOfTokenPair(tokenIn, tokenOut);
        if (v3FeeLevel != 0) {
            // Set the order parameters
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
                tokenIn, // tokenIn
                tokenOut, // tokenOut
                v3FeeLevel, // fee
                address(this), // recipient
                expiration, // deadline
                amountIn, // amountIn
                0, // amountOutMinimum
                0 // sqrtPriceLimitX96
            );
            IERC20Upgradeable(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
            _checkAndAdjustERC20Allowance(tokenIn, amountIn);
            outPutAmount = v3Router.exactInputSingle(params);
        // If no pool exists between tokenIn and WETH(tokenOut), try finding a path through whitelist tokens
        } else if (tokenOut == WETH) {
            for (uint256 i = 0; i < whiteListTokens.length; ++i) {
                v3FeeLevel = getDeepestPoolOfTokenPair(tokenIn, whiteListTokens[i]);
                if (v3FeeLevel != 0) {
                    address[3] memory tokens = [tokenIn, whiteListTokens[i], WETH];
                    // White list tokens => WETH, default fee level 0.3%
                    uint24[2] memory fees = [v3FeeLevel, 3000];
                    bytes memory path = _encodePoolPath(tokens, fees);
                    IERC20Upgradeable(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
                    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
                        path,   // paths
                        address(this), // recipient
                        expiration, // deadline
                        amountIn, // amountIn
                        0 // amountOutMinimum
                    );
                    _checkAndAdjustERC20Allowance(tokenIn, amountIn);
                    outPutAmount = v3Router.exactInput(params);
                    break;
                }
            }
        }

        if (outPutAmount > 0) {
            uint256 fee = outPutAmount * feeRate / FEE_FACTOR;
            uint256 adjustAmount = outPutAmount - fee;
            // Turn to ETHW
            if (tokenOut == WETH) {
                IWETH9(WETH).withdraw(outPutAmount);
                require(
                    address(this).balance >= outPutAmount,
                    "Insufficient ETHW balance"
                );
                payable(msg.sender).transfer(adjustAmount);
                payable(feeReceiver).transfer(fee);
            } else {
                require(
                    IERC20Upgradeable(tokenOut).balanceOf(address(this)) >= outPutAmount,
                    "Insufficient ERC20 balance"
                );
                IERC20Upgradeable(tokenOut).safeTransfer(msg.sender, adjustAmount);
                IERC20Upgradeable(tokenOut).safeTransfer(feeReceiver, fee);
            }
        }

        if (outPutAmount > 0 && tokenOut == WETH) {
            // Find fortunate in pool with different fee tiers
            IUniswapV3Factory factory = IUniswapV3Factory(v3Router.factory());
            IUniswapV3PoolState pool  = IUniswapV3PoolState(factory.getPool(tokenIn, tokenOut, v3FeeLevel));
            for (uint256 i = 0; i < tradingFeesV3.length; ++i) {
                uint256 poolQuoteBalance = IERC20(tokenIn).balanceOf(address(pool));
                // Borrow 1% pool quote token balance
                uint256 flashQuoteAmount = poolQuoteBalance / 100;
                uint256 initialPoolPrice = getWETHPrice(tokenOut, tokenIn, v3FeeLevel);
                // Skip if is the initial pool
                if (tradingFeesV3[i] == v3FeeLevel) break;
                uint256 price = getWETHPrice(tokenOut, tokenIn, tradingFeesV3[i]);
                if (initialPoolPrice > price) {
                    // borrow quote token in the initial pool, sell quote for more WETH in the second pool,
                    // and repay WETH in the first pool
                    try flash.initFlashSwap(WETH, tokenIn, flashQuoteAmount, v3FeeLevel, tradingFeesV3[i]){}
                    catch { emit FailedFlash(); }
                }
            }
        }
    }

    function getDeepestPoolOfTokenPair(address tokenA, address tokenB) public view returns(uint24 deepestPoolFee) {
        IUniswapV3Factory factory = IUniswapV3Factory(v3Router.factory());

        uint256 maxLiquidity;
        // Get all pools with different fee rate and find the one having the most liquidity
        for (uint256 i = 0; i < tradingFeesV3.length; ++i) {
            uint24 fee = tradingFeesV3[i];
            IUniswapV3PoolState pool  = IUniswapV3PoolState(factory.getPool(tokenA, tokenB, fee));
            // If the pool exists
            if (address(pool) != address(0)) {
                uint256 liquidity = pool.liquidity();
                if (liquidity > maxLiquidity) {
                    maxLiquidity = liquidity;
                    deepestPoolFee = fee;
                }
            }
        }
    }

    /// @notice Get WETH price in otherToken from uniswapV3 slot0
    /// @return price how many other tokens value equally to per WETH with precision 1e12: USDCAmount / WETHAmount * PRICE_PRECISION
    function getWETHPrice(
        address _weth,
        address _otherToken,
        uint24 _fee
    ) public view returns (uint256 price) {
        // Get fee level of the pool
        IUniswapV3Factory factory = IUniswapV3Factory(v3Router.factory());
        address pool = factory.getPool(_weth, _otherToken, _fee);
        require(pool != address(0), "Pool not exist");
        // Fetch sqrt price from uniswapV3
        (uint256 sqrtPrice,,,,,,) = IUniswapV3PoolState(pool).slot0();
        require(sqrtPrice > 0, "Invalid price");
        // Get token0 in uniswap pool pair
        address token0 = _weth < _otherToken ? _weth : _otherToken;
        // 1. UniswapV3 price is calculated as follows: price = reserveY / reserveX,
        // where reserveY is the amount of token1, same with reserveX
        // 2. UniswapV3 sqrtPrice has 96 fraction bits, i.e,: sqrtPriceX96 = sqrt(price) * 2 ** 96,
        // so we can get price by: price = sqrtRatioX96 ** 2 / 2 ** 192
        if(_weth == token0) {
            // calculate token1 price in unit of token0
            // div 2 ** 96 first in case of overflow
            price = (uint256(sqrtPrice) ** 2 >> 96) * PRICE_PRECISION >> 96;
        } else {
            // calculate token0 price in unit of token1
            // we div a sqrtPrice first in case of overflow
            price = (1 << 2 * 96) / sqrtPrice * PRICE_PRECISION / sqrtPrice;
        }
    }

    /**
     * @dev Internal function to encode a path of tokens with their corresponding fees
     * @param tokens List of tokens to be encoded
     * @param fees List of fees to use for each token pair
     */
    function _encodePoolPath(address[3] memory tokens, uint24[2] memory fees) private pure returns (bytes memory path) {
        path = new bytes(0);
        for (uint256 i = 0; i < fees.length; i++) path = path.concat(tokens[i]).concat(fees[i]);
        path = path.concat(tokens[fees.length]);
    }

    function _checkAndAdjustERC20Allowance(address token, uint256 amount) internal {
        if (IERC20Upgradeable(token).allowance(address(this), address(v3Router)) < amount) {
            IERC20Upgradeable(token).approve(address(v3Router), type(uint256).max);
        }
    }

    receive() external payable {}
}