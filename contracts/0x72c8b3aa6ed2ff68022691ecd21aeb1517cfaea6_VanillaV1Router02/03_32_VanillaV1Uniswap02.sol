// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "./TickMath.sol";
import "./VanillaV1Constants02.sol";

/**
    @title The Uniswap v3-enabled base contract for Vanilla.
*/
contract VanillaV1Uniswap02 is IUniswapV3SwapCallback, VanillaV1Constants02 {

    address internal immutable _uniswapFactoryAddr;
    address internal immutable _wethAddr;

    // for ensuring the authenticity of swapCallback caller, also reentrancy/delegatecall control
    address private authorizedPool;
    address private immutable sentinelValue; // sentinelValue _must_ be immutable

    /**
        @notice Deploys the contract and initializes Uniswap contract references
        @dev using UniswapRouter to ensure that Vanilla uses the same WETH contract
        @param router The Uniswap periphery contract implementing the IPeripheryImmutableState
     */
    constructor(IPeripheryImmutableState router) {
        // fetch addresses via router to guarantee correctness
        _wethAddr = router.WETH9();
        _uniswapFactoryAddr = router.factory();

        // we use address(this) as non-zero sentinel value for gas optimization
        sentinelValue = address(this);
        authorizedPool = address(this);
    }

    // because Uniswap V3 swaps are implemented with callback mechanisms, the callback-function becomes a public interface for
    // transferring tokens away from custody, so we want to make sure that we only authorize a _single Uniswap pool_ to
    // call the uniswapV3SwapCallback-function
    modifier onlyAuthorizedUse(IUniswapV3Pool pool) {
        address sentinel = sentinelValue;
        // protect the swap against any potential reentrancy (authorizedPool is set to to pool's address before
        // first swap and resetted back to sentinelValue
        if (authorizedPool != sentinel) {
            revert UnauthorizedReentrantAccess();
        }

        // delegatecalling the callback function should not be a problem, but there's no reason to allow that
        if (address(this) != sentinel) {
            revert UnauthorizedDelegateCall();
        }
        authorizedPool = address(pool);
        _;
        // set back to original, non-zero address for a refund
        authorizedPool = sentinel;
    }
    // this modifier needs to be used on every Uniswap v3 pool callback functions whose access is authorized by `onlyAuthorizedUse` modifier
    modifier onlyAuthorizedCallback() {
        if (msg.sender != authorizedPool) {
            revert UnauthorizedCallback();
        }
        _;
    }


    struct SwapParams {
        address source;
        address recipient;
        uint256 tokensIn;
        uint256 tokensOut;
        address tokenIn;
        address tokenOut;
    }
    function _swapToken0To1(IUniswapV3Pool pool, SwapParams memory params)
    private
    onlyAuthorizedUse(pool)
    returns (uint256 numTokens) {

        // limits are verified in the callback function to optimize gas
        uint256 balanceBefore = IERC20(params.tokenOut).balanceOf(params.recipient);
        (,int256 amountOut) = pool.swap(
            params.recipient,
            true, // "zeroForOne": The direction of the swap, true for token0 to token1, false for token1 to token0
            int256(params.tokensIn),
            TickMath.MIN_SQRT_RATIO+1,
            abi.encode(balanceBefore, params)
        );

        // v3 pool uses sign the represents the flow of tokens into the pool, so negative amount means tokens leaving
        if (amountOut > 0 || uint256(-amountOut) < params.tokensOut) {
            revert InvalidSwap(params.tokensOut, amountOut);
        }
        numTokens = uint256(-amountOut);
    }

    function _swapToken1To0(IUniswapV3Pool pool, SwapParams memory params)
    private onlyAuthorizedUse(pool)
    returns (uint256 numTokens) {

        // limits are verified in the callback function to optimize gas
        uint256 balanceBefore = IERC20(params.tokenOut).balanceOf(params.recipient);
        (int256 amountOut,) = pool.swap(
            params.recipient,
            false, // "zeroForOne": The direction of the swap, true for token0 to token1, false for token1 to token0
            int256(params.tokensIn),
            TickMath.MAX_SQRT_RATIO-1,
            abi.encode(balanceBefore, params)
        );

        // v3 pool uses sign the represents the flow of tokens into the pool, so negative amount means tokens leaving
        if (amountOut > 0 || uint256(-amountOut) < params.tokensOut) {
            revert InvalidSwap(params.tokensOut, amountOut);
        }
        numTokens = uint256(-amountOut);
    }

    function _buy(address token,
        uint256 numEth,
        uint256 limit,
        address wethHolder,
        uint24 fee) internal returns (uint256 numTokens) {
        (IUniswapV3Pool pool, bool tokenFirst) = _v3pool(token, fee);
        if (address(pool) == address(0)) {
            revert UninitializedUniswapPool(token, fee);
        }

        SwapParams memory params = SwapParams({
            source: wethHolder,
            recipient: address(this),
            tokensIn: numEth,
            tokensOut: limit,
            tokenIn: _wethAddr,
            tokenOut: token
        });
        if (tokenFirst) {
            numTokens = _swapToken1To0(pool, params);
        }
        else {
            numTokens = _swapToken0To1(pool, params);
        }
    }

    struct RewardParams {
        uint256 numEth;
        uint256 expectedAvgEth;
        uint32 averagePeriodInSeconds;
    }

    function _sell(
        address token,
        uint256 numTokens,
        uint256 limit,
        uint24 fee,
        address recipient) internal returns (RewardParams memory) {
        (IUniswapV3Pool pool, bool tokenFirst) = _v3pool(token, fee);
        if (address(pool) == address(0)) {
            revert UninitializedUniswapPool(token, fee);
        }

        SwapParams memory params = SwapParams({
            source: address(this),
            recipient: recipient,
            tokensIn: numTokens,
            tokensOut: limit,
            tokenIn: token,
            tokenOut: _wethAddr
        });
        ObservedEntry memory oldest = oldestObservation(pool);
        if (!oldest.poolInitialized) {
            revert UninitializedUniswapPool(token, fee);
        }
        if (tokenFirst) {
            (uint160 avgSqrtPrice, uint32 period) = calculateTWAP(pool, oldest);
            uint256 numEth = _swapToken0To1(pool, params);
            return RewardParams({
                numEth: numEth,
                expectedAvgEth: expectedEthForToken0(numTokens, avgSqrtPrice),
                averagePeriodInSeconds: period
            });
        }
        else {
            (uint160 avgSqrtPrice, uint32 period) = calculateTWAP(pool, oldest);
            uint256 numEth = _swapToken1To0(pool, params);
            return RewardParams({
                numEth: numEth,
                expectedAvgEth: expectedEthForToken1(numTokens, avgSqrtPrice),
                averagePeriodInSeconds: period
            });
        }
    }

    function estimateRewardParams(address token, uint256 numTokens, uint24 fee) internal view returns (
        RewardParams memory) {

        (IUniswapV3Pool pool, bool tokenFirst) = _v3pool(token, fee);
        if (address(pool) == address(0)) {
            return RewardParams({
                numEth: 0,
                expectedAvgEth: 0,
                averagePeriodInSeconds: 0
            });
        }

        ObservedEntry memory oldest = oldestObservation(pool);
        if (!oldest.poolInitialized) {
            return RewardParams({
                numEth: 0,
                expectedAvgEth: 0,
                averagePeriodInSeconds: 0
            });
        }

        (uint160 avgSqrtPrice, uint32 period) = calculateTWAP(pool, oldest);
        if (tokenFirst) {
            return RewardParams({
                numEth: 0, // really wish Uniswap v3 had provided a read-only API for querying this
                expectedAvgEth: expectedEthForToken0(numTokens, avgSqrtPrice),
                averagePeriodInSeconds: period
            });
        }
        else {
            return RewardParams({
                numEth: 0,
                expectedAvgEth: expectedEthForToken1(numTokens, avgSqrtPrice),
                averagePeriodInSeconds: period
            });
        }
    }

    struct ObservedEntry {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint16 observationCardinality;
        bool poolInitialized;
    }
    function oldestObservation(IUniswapV3Pool pool) internal view returns (ObservedEntry memory) {
        (,,uint16 observationIndex, uint16 observationCardinality,,,) = pool.slot0();
        if (observationCardinality == 0) {
            return ObservedEntry(0,0,0, false);
        }
        uint16 oldestIndex = uint16((uint32(observationIndex) + 1) % observationCardinality);
        {
            // it's important to check if the observation in oldestIndex is initialized, because if it's not, then
            // the oracle has not been fully initialized after pool.increaseObservationCardinalityNext() and oldest
            // observation is actually the index 0
            (uint32 blockTimestamp, int56 tickCumulative,, bool initialized) = pool.observations(oldestIndex);
            if (initialized) {
                return ObservedEntry({
                    blockTimestamp: blockTimestamp,
                    tickCumulative: tickCumulative,
                    observationCardinality: observationCardinality,
                    poolInitialized: true
                });
            }
        }
        {
            (uint32 blockTimestamp, int56 tickCumulative,,) = pool.observations(0);

            return ObservedEntry({
                blockTimestamp: blockTimestamp,
                tickCumulative: tickCumulative,
                observationCardinality: observationCardinality,
                poolInitialized: true
            });
        }

    }

    function getSqrtRatioAtAverageTick(uint period, int tickCumulativeDiff) pure internal returns (uint160) {
        int24 avgTick = int24(tickCumulativeDiff / int(uint(period)));
        // round down to negative infinity is correct behavior for tick math
        if (tickCumulativeDiff < 0 && (tickCumulativeDiff % int(uint(period)) != 0)) avgTick--;

        return TickMath.getSqrtRatioAtTick(avgTick);
    }


    function expectedEthForToken1(uint numTokens, uint sqrtPriceX96) internal pure returns (uint) {
        if (sqrtPriceX96 == 0) {
            // calculated average price can be 0 when no swaps has been done and observations are not updated
            return 0;
        }
        // derivation from the whitepaper equations when weth is the token0:
        // Q96 = 2^96, sqrtPriceX96 = Q*sqrt(price) = sqrt(numTokens/numEth)
        // => (sqrtPriceX96/Q96)^2 = numTokens/numEth
        // => numEth = numTokens / sqrtPriceX96^2 / Q96^2
        //           = (Q96^2 * numTokens) / sqrtPriceX96^2
        //           = (2 ** 192) * numTokens / (sqrtPriceX96 ** 2)
        if (numTokens < Q64 && sqrtPriceX96 < Q128) {
            return Q192 * numTokens / (sqrtPriceX96 ** 2);
        }
        else {
            // either numTokens or price is too high for full precision math within a uint256, so we derive an alternative where
            // the fixedpoint resolution is reduced from Q96 to Q64:
            //    ((sqrtPriceX96/2^32) / (Q96/2^32))^2 = numTokens/numEth
            // => ((sqrtPriceX64) / (Q64))^2 = numTokens/numEth
            // => ((sqrtPriceX64) / (Q64))^2 = numTokens/numEth
            // => numEth = numTokens / sqrtPriceX64^2 / Q64^2
            //           = (2 ** 128 * numTokens ) / sqrtPriceX64^2

            // this makes the overflow practically impossible, but increases the precision loss (which is acceptable since this
            // math is only used for estimating reward parameters)
            uint sqrtPriceX64 = sqrtPriceX96 / 2**32;
            return (Q128 * numTokens) / (sqrtPriceX64**2);
        }
    }


    function expectedEthForToken0(uint numTokens, uint sqrtPriceX96) internal pure returns (uint) {
        if (sqrtPriceX96 == 0) {
            // calculated average price can be 0 when no swaps has been done and observations are not updated
            return 0;
        }
        if (numTokens == 0) {
            return 0;
        }
        // derivation from the whitepaper equations when weth is the token1:
        // Q96 = 2^96, sqrtPriceX96 = Q*sqrt(price) = sqrt(numEth/numTokens)
        // => (sqrtPriceX96/Q96)^2 = numEth/numTokens
        // => numEth = numTokens * sqrtPriceX96^2 / Q96^2
        //           = (2 ** 192) * numTokens / (sqrtPriceX96 ** 2)
        //           = sqrtPriceX96 ** 2 / (2 ** 192 / numTokens)
        if (sqrtPriceX96 < Q128) {
            return (sqrtPriceX96 ** 2) / (Q192 / numTokens);
        }
        else {
            // if price is too high for full precision math within a uint256, we derive an alternative where
            // the fixedpoint resolution is reduced from Q96 to Q64:
            //    ((sqrtPriceX96/2^32) / (Q96/2^32))^2 = numEth/numTokens
            // => ((sqrtPriceX64) / (Q64))^2 = numEth/numTokens
            // => numEth = numTokens * sqrtPriceX64^2 / Q64^2
            //           = sqrtPriceX64 ** 2 / (2 ** 128 / numTokens)
            // the level of precision loss is acceptable since this math is only used for estimating reward parameters
            uint sqrtPriceX64 = sqrtPriceX96 / 2**32;
            return (sqrtPriceX64**2) / (Q128 / numTokens);
        }
    }

    function calculateTWAP(IUniswapV3Pool pool, ObservedEntry memory preSwap) internal view returns (uint160 avgSqrtPrice, uint32 period) {
        if (preSwap.observationCardinality == 1) {
            return (0, 0);
        }
        period = uint32(Math.min(block.timestamp - preSwap.blockTimestamp, MAX_TWAP_PERIOD));
        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = period;
        secondAgos[1] = 0;
        (int56[] memory tickCumulatives, ) = pool.observe(secondAgos);
        avgSqrtPrice = getSqrtRatioAtAverageTick(period, tickCumulatives[1] - tickCumulatives[0]);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override onlyAuthorizedCallback {
        if (amount1Delta < 0 && amount0Delta < 0) {
            // this should never happen, but in case it does, it would wreck these calculations so check and revert
            revert InvalidUniswapState();
        }

        // if delta0 is positive (meaning tokens are expected to increase in the pool) then delta1 is negative
        // (meaning pool's token amounts are expected to decrease), and vice versa
        (uint256 amountIn, uint256 amountOut) = amount0Delta > 0 ?
            (uint256(amount0Delta), uint256(-amount1Delta)) :
            (uint256(amount1Delta), uint256(-amount0Delta));

        (uint256 balanceBeforeSwap, SwapParams memory params) = abi.decode(data, (uint256, SwapParams));

        // Pool has already transferred the `amountOut` tokens to recipient, so check the limit before transferring the tokens
        if (IERC20(params.tokenOut).balanceOf(params.recipient) < balanceBeforeSwap + params.tokensOut) {
            revert SlippageExceeded(params.tokensOut, amountOut);
        }

        // check if for some reason the pool actually tries to request more tokens than user allowed
        if (amountIn > params.tokensIn) {
            revert AllowanceExceeded(params.tokensIn, amountIn);
        }

        if (params.source == address(this)) {
            IERC20(params.tokenIn).transfer(msg.sender, amountIn);
        }
        else {
            IERC20(params.tokenIn).transferFrom(params.source, msg.sender, amountIn);
        }
    }

    function _v3pool(
        address token,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool, bool tokenFirst) {
        // save an SLOAD
        address weth = _wethAddr;

        // as order of tokens is important in Uniswap pairs, we record this information here and pass it on to caller
        // for gas optimization
        tokenFirst = token < weth;

        // it's better to just query UniswapV3Factory for pool address instead of calculating the CREATE2 address
        // ourselves, as there are now three fee-tiers it's not guaranteed that all three are created for WETH-pairs
        // and any subsequent calls to non-existing pool will fail - and the UniswapV3Factory holds the canonical information
        // of which fee tiers are created
        // (and after EIP-2929, the uniswap factory address can be added to warmup accesslist which makes the call cost
        // insignificant compared to safety and simplicity gains)
        pool = IUniswapV3Pool(IUniswapV3Factory(_uniswapFactoryAddr).getPool(token, weth, fee));
    }

}