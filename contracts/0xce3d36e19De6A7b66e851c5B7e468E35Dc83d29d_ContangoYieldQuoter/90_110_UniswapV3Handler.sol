//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../libraries/DataTypes.sol";
import "../dependencies/Uniswap.sol";

library UniswapV3Handler {
    using SignedMath for int256;
    using PoolAddress for address;

    error InvalidCallbackCaller(address caller);

    error InsufficientHedgeAmount(uint256 hedgeSize, uint256 swapAmount);

    error InvalidAmountDeltas(int256 amount0Delta, int256 amount1Delta);

    struct Callback {
        CallbackInfo info;
        Instrument instrument;
        Fill fill;
    }

    struct CallbackInfo {
        Symbol symbol;
        PositionId positionId;
        address trader;
        uint256 limitCost;
        address payerOrReceiver;
        bool open;
        uint256 lendingLiquidity;
    }

    address internal constant UNISWAP_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /// @notice Executes a flash swap on Uni V3, to buy/sell the hedgeSize
    /// @param callback Info collected before the flash swap started
    /// @param instrument The instrument being swapped
    /// @param baseForQuote True if base if being sold
    /// @param to The address to receive the output of the swap
    function flashSwap(Callback memory callback, Instrument memory instrument, bool baseForQuote, address to)
        internal
    {
        callback.instrument = instrument;

        (address tokenIn, address tokenOut) = baseForQuote
            ? (address(instrument.base), address(instrument.quote))
            : (address(instrument.quote), address(instrument.base));

        bool zeroForOne = tokenIn < tokenOut;
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(tokenIn, tokenOut, instrument.uniswapFeeTransient);

        IUniswapV3Pool(UNISWAP_FACTORY.computeAddress(poolKey)).swap({
            recipient: to,
            zeroForOne: zeroForOne,
            amountSpecified: baseForQuote ? int256(callback.fill.hedgeSize) : -int256(callback.fill.hedgeSize),
            sqrtPriceLimitX96: (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
            data: abi.encode(callback)
        });
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data,
        function(UniswapV3Handler.Callback memory) internal onUniswapCallback
    ) internal {
        if (amount0Delta < 0 && amount1Delta < 0 || amount0Delta > 0 && amount1Delta > 0) {
            revert InvalidAmountDeltas(amount0Delta, amount1Delta);
        }

        Callback memory callback = abi.decode(data, (Callback));
        Instrument memory instrument = callback.instrument;
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.getPoolKey(address(instrument.base), address(instrument.quote), instrument.uniswapFeeTransient);

        if (msg.sender != UNISWAP_FACTORY.computeAddress(poolKey)) {
            revert InvalidCallbackCaller(msg.sender);
        }

        bool amount0isBase = instrument.base < instrument.quote;
        uint256 swapAmount = (amount0isBase ? amount0Delta : amount1Delta).abs();

        if (callback.fill.hedgeSize != swapAmount) {
            revert InsufficientHedgeAmount(callback.fill.hedgeSize, swapAmount);
        }

        callback.fill.hedgeCost = (amount0isBase ? amount1Delta : amount0Delta).abs();
        onUniswapCallback(callback);
    }
}