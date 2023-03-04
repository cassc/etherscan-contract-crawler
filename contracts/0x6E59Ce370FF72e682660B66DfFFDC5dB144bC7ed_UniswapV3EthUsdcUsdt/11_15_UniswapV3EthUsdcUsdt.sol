// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Defii} from "../Defii.sol";
import {DefiiWithCustomEnter} from "../DefiiWithCustomEnter.sol";
import {DefiiWithCustomExit} from "../DefiiWithCustomExit.sol";

contract UniswapV3EthUsdcUsdt is DefiiWithCustomEnter, DefiiWithCustomExit {
    using SafeERC20 for IERC20;

    INonfungiblePositionManager constant nfpManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    /// @notice Encode params for enterWithParamas function
    /// @param tickLower Left tick for position
    /// @param tickUpper Right tick for position
    /// @param fee The pool's fee in hundredths of a bip, i.e. 1e-6 (e.g 100 for 0.01%)
    /// @return encodedParams Encoded params for enterWithParams function
    function enterParams(
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external view returns (bytes memory encodedParams) {
        uint256 usdcBalance = USDC.balanceOf(address(this));

        IUniswapV3Pool pool = nfpManager.factory().getPool(USDC, USDT, fee);
        (uint256 sqrtPriceX96, int24 tickCurrent, , , , , ) = pool.slot0();
        uint256 token0AmountToSwap = calcToken0AmountToSwap(
            tickLower,
            tickUpper,
            tickCurrent,
            sqrtPriceX96,
            usdcBalance
        );

        encodedParams = abi.encode(
            tickLower,
            tickUpper,
            fee,
            findNft(tickLower, tickUpper, fee),
            token0AmountToSwap
        );
    }

    function findNft(
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) public view returns (uint256) {
        uint256 numPositions = nfpManager.balanceOf(address(this));
        for (uint256 i = 0; i < numPositions; i++) {
            uint256 positionId = nfpManager.tokenOfOwnerByIndex(
                address(this),
                i
            );

            (
                ,
                ,
                ,
                ,
                uint24 positionFee,
                int24 positionTickLower,
                int24 positionTickUpper,
                ,
                ,
                ,
                ,

            ) = nfpManager.positions(positionId);

            if (
                tickLower == positionTickLower &&
                tickUpper == positionTickUpper &&
                fee == positionFee
            ) {
                return positionId;
            }
        }
        return 0;
    }

    function calcToken0AmountToSwap(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 P,
        uint256 token0Balance
    ) public pure returns (uint256 token0AmountToSwap) {
        if (tickLower > tickCurrent) return 0;
        if (tickUpper < tickCurrent) return token0Balance;

        uint256 Q96 = 0x1000000000000000000000000;
        uint256 Q64 = 0x10000000000000000;
        uint256 Q32 = 0x100000000;

        uint256 pa = TickMath.getSqrtRatioAtTick(tickLower);
        uint256 pb = TickMath.getSqrtRatioAtTick(tickUpper);

        uint256 num = P * pb;
        uint256 denom = pb - P;

        // k in Q32 format
        uint256 k = ((num / denom) * (P - pa)) / Q96 / Q64;

        uint256 token0AmountToLiquidity = (token0Balance * Q32) / (k + Q32);
        token0AmountToSwap = token0Balance - token0AmountToLiquidity;
    }

    function exitParams(uint256 positionId)
        external
        pure
        returns (bytes memory encodedParams)
    {
        encodedParams = abi.encode(positionId);
    }

    function hasAllocation() public view override returns (bool) {
        return nfpManager.balanceOf(address(this)) > 0;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external view returns (bytes4) {
        require(tx.origin == owner, "Only owner could init tx with NFT mint");
        return this.onERC721Received.selector;
    }

    function _postInit() internal override {
        USDC.approve(address(nfpManager), type(uint256).max);
        USDC.approve(address(router), type(uint256).max);
        USDT.safeIncreaseAllowance(address(nfpManager), type(uint256).max);
    }

    function _enterWithParams(bytes memory params) internal override {
        (
            int24 tickLower,
            int24 tickUpper,
            uint24 fee,
            uint256 nftId,
            uint256 usdcToSwap
        ) = abi.decode(params, (int24, int24, uint24, uint256, uint256));

        if (usdcToSwap > 0) {
            router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(USDC),
                    tokenOut: address(USDT),
                    fee: 100,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: usdcToSwap,
                    amountOutMinimum: (usdcToSwap * 999) / 1000, // slippage 0.1 %
                    sqrtPriceLimitX96: 0
                })
            );
        }

        uint256 usdcAmount = USDC.balanceOf(address(this));
        uint256 usdtAmount = USDT.balanceOf(address(this));

        if (nftId > 0) {
            nfpManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: nftId,
                    amount0Desired: usdcAmount,
                    amount1Desired: usdtAmount,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );
        } else {
            nfpManager.mint(
                INonfungiblePositionManager.MintParams({
                    token0: address(USDC),
                    token1: address(USDT),
                    fee: fee,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: usdcAmount,
                    amount1Desired: usdtAmount,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: block.timestamp
                })
            );
        }
    }

    function _exit() internal override(Defii, DefiiWithCustomExit) {
        uint256 numPositions = nfpManager.balanceOf(address(this));
        for (uint256 i = 0; i < numPositions; i++) {
            uint256 positionId = nfpManager.tokenOfOwnerByIndex(
                address(this),
                i
            );
            _exitOnePosition(positionId);
        }
    }

    function _exitWithParams(bytes memory params) internal override {
        uint256 positionId = abi.decode(params, (uint256));
        _exitOnePosition(positionId);
    }

    function _exitOnePosition(uint256 positionId) internal {
        (, , , , , , , uint128 positionLiquidity, , , , ) = nfpManager
            .positions(positionId);

        nfpManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: positionId,
                liquidity: positionLiquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
        nfpManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: positionId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function _harvest() internal override {
        INonfungiblePositionManager.CollectParams memory collectParams;
        uint256 numPositions = nfpManager.balanceOf(address(this));
        for (uint256 i = 0; i < numPositions; i++) {
            uint256 positionId = nfpManager.tokenOfOwnerByIndex(
                address(this),
                i
            );

            collectParams.tokenId = positionId;
            collectParams.recipient = address(this);
            collectParams.amount0Max = type(uint128).max;
            collectParams.amount1Max = type(uint128).max;
            nfpManager.collect(collectParams);
        }
        _withdrawFunds();
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
        withdrawERC20(USDT);
    }
}

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint24(MAX_TICK), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }
}

interface IUniswapV3Factory {
    function getPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint24 fee
    ) external view returns (IUniswapV3Pool pool);
}

interface INonfungiblePositionManager is IERC721Enumerable {
    function factory() external view returns (IUniswapV3Factory);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}