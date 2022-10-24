// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ABDKMath64x64.sol";
import "./Utils.sol";

/**
 * Helper library for Uniswap functions
 * Used in CLR
 */
library UniswapLibrary {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint8 private constant TOKEN_DECIMAL_REPRESENTATION = 18;
    uint256 private constant SWAP_SLIPPAGE = 50; // 2%
    uint256 private constant MINT_BURN_SLIPPAGE = 100; // 1%

    struct TokenDetails {
        address token0;
        address token1;
        uint256 token0DecimalMultiplier;
        uint256 token1DecimalMultiplier;
        uint8 token0Decimals;
        uint8 token1Decimals;
        // used to account for token 0 or token 1 matching reward token in buffer
        uint256 rewardAmountRemainingToken0;
        uint256 rewardAmountRemainingToken1;
    }

    struct PositionDetails {
        uint24 poolFee;
        uint32 twapPeriod;
        uint160 priceLower;
        uint160 priceUpper;
        uint256 tokenId;
        address positionManager;
        address router;
        address quoter;
        address pool;
    }

    struct AmountsMinted {
        uint256 amount0ToMint;
        uint256 amount1ToMint;
        uint256 amount0Minted;
        uint256 amount1Minted;
    }

    /* ========================================================================================= */
    /*                                  Uni V3 Pool Helper functions                             */
    /* ========================================================================================= */

    /**
     * @dev Returns the current pool price in X96 notation
     */
    function getPoolPrice(address _pool) public view returns (uint160) {
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return sqrtRatioX96;
    }

    /**
     * Get pool price in decimal notation with 12 decimals
     */
    function getPoolPriceWithDecimals(
        address _pool,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public view returns (uint256 price) {
        uint160 sqrtRatioX96 = getPoolPrice(_pool);
        uint8 tokenDecimalDiff = token0Decimals >= token1Decimals
            ? token0Decimals - token1Decimals
            : token1Decimals - token0Decimals;
        return
            token0Decimals >= token1Decimals
                ? (uint256(sqrtRatioX96).mul(uint256(sqrtRatioX96)).mul(
                    10**(12 + tokenDecimalDiff)
                ) >> 192)
                : (uint256(sqrtRatioX96).mul(uint256(sqrtRatioX96)).mul(
                    10**(12 - tokenDecimalDiff)
                ) >> 192);
    }

    /**
     * @dev Returns the current pool liquidity
     */
    function getPoolLiquidity(address _pool) public view returns (uint128) {
        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        return pool.liquidity();
    }

    function getLiquidityForAmount0(
        uint160 priceLower,
        uint160 priceUpper,
        uint256 amount0
    ) public pure returns (uint128 liquidity) {
        liquidity = LiquidityAmounts.getLiquidityForAmount0(
            priceLower,
            priceUpper,
            amount0
        );
    }

    function getLiquidityForAmount1(
        uint160 priceLower,
        uint160 priceUpper,
        uint256 amount1
    ) public pure returns (uint128 liquidity) {
        liquidity = LiquidityAmounts.getLiquidityForAmount1(
            priceLower,
            priceUpper,
            amount1
        );
    }

    /**
     * @dev Calculate pool liquidity for given token amounts
     */
    function getLiquidityForAmounts(
        uint256 amount0,
        uint256 amount1,
        uint160 priceLower,
        uint160 priceUpper,
        address pool
    ) public view returns (uint128 liquidity) {
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            getPoolPrice(pool),
            priceLower,
            priceUpper,
            amount0,
            amount1
        );
    }

    /**
     * @dev Calculate token amounts for given pool liquidity
     */
    function getAmountsForLiquidity(
        uint128 liquidity,
        uint160 priceLower,
        uint160 priceUpper,
        address pool
    ) public view returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            getPoolPrice(pool),
            priceLower,
            priceUpper,
            liquidity
        );
    }

    /**
     * @dev Calculates the amounts deposited/withdrawn from the pool
     * @param amount0 - token0 amount to deposit/withdraw
     * @param amount1 - token1 amount to deposit/withdraw
     */
    function calculatePoolMintedAmounts(
        uint256 amount0,
        uint256 amount1,
        uint160 priceLower,
        uint160 priceUpper,
        address pool
    ) public view returns (uint256 amount0Minted, uint256 amount1Minted) {
        uint128 liquidityAmount = getLiquidityForAmounts(
            amount0,
            amount1,
            priceLower,
            priceUpper,
            pool
        );
        (amount0Minted, amount1Minted) = getAmountsForLiquidity(
            liquidityAmount,
            priceLower,
            priceUpper,
            pool
        );
    }

    /* ========================================================================================= */
    /*                              Uni V3 Swap Router Helper functions                          */
    /* ========================================================================================= */

    /**
     * @dev Swap token 0 for token 1 in CLR contract
     * @dev amountIn and amountOut should be in 18 decimals always
     * @dev amountIn and amountOut are in token 0 terms
     */
    function swapToken0ForToken1(
        uint256 amountIn,
        uint256 amountOut,
        PositionDetails memory positionDetails,
        TokenDetails memory tokenDetails
    ) public returns (uint256 _amountOut) {
        uint256 midPrice = getPoolPriceWithDecimals(
            positionDetails.pool,
            tokenDetails.token0Decimals,
            tokenDetails.token1Decimals
        );
        amountOut = amountOut.mul(midPrice).div(1e12);
        uint256 token0Balance = getBufferToken0Balance(
            IERC20(tokenDetails.token0),
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier,
            tokenDetails.rewardAmountRemainingToken0
        );
        require(
            token0Balance >= amountIn,
            "Swap token 0 for token 1: not enough token 0 balance"
        );

        amountIn = getToken0AmountInNativeDecimals(
            amountIn,
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier
        );
        amountOut = getToken1AmountInNativeDecimals(
            amountOut,
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier
        );

        uint256 amountOutExpected = IQuoter(positionDetails.quoter)
            .quoteExactInputSingle(
                tokenDetails.token0,
                tokenDetails.token1,
                positionDetails.poolFee,
                amountIn,
                TickMath.MIN_SQRT_RATIO + 1
            );

        if (amountOutExpected < amountOut) {
            amountOut = amountOutExpected;
        }

        ISwapRouter(positionDetails.router).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenDetails.token0,
                tokenOut: tokenDetails.token1,
                fee: positionDetails.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountIn,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
            })
        );
        return amountOut;
    }

    /**
     * @dev Swap token 1 for token 0 in CLR contract
     * @dev amountIn and amountOut should be in 18 decimals always
     * @dev amountIn and amountOut are in token 1 terms
     */
    function swapToken1ForToken0(
        uint256 amountIn,
        uint256 amountOut,
        PositionDetails memory positionDetails,
        TokenDetails memory tokenDetails
    ) public returns (uint256 _amountIn) {
        uint256 midPrice = getPoolPriceWithDecimals(
            positionDetails.pool,
            tokenDetails.token0Decimals,
            tokenDetails.token1Decimals
        );
        amountOut = amountOut.mul(1e12).div(midPrice);
        uint256 token1Balance = getBufferToken1Balance(
            IERC20(tokenDetails.token1),
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier,
            tokenDetails.rewardAmountRemainingToken1
        );
        require(
            token1Balance >= amountIn,
            "Swap token 1 for token 0: not enough token 1 balance"
        );

        amountIn = getToken1AmountInNativeDecimals(
            amountIn,
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier
        );
        amountOut = getToken0AmountInNativeDecimals(
            amountOut,
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier
        );

        uint256 amountOutExpected = IQuoter(positionDetails.quoter)
            .quoteExactInputSingle(
                tokenDetails.token1,
                tokenDetails.token0,
                positionDetails.poolFee,
                amountIn,
                TickMath.MAX_SQRT_RATIO - 1
            );

        if (amountOutExpected < amountOut) {
            amountOut = amountOutExpected;
        }

        ISwapRouter(positionDetails.router).exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenDetails.token1,
                tokenOut: tokenDetails.token0,
                fee: positionDetails.poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountIn,
                sqrtPriceLimitX96: TickMath.MAX_SQRT_RATIO - 1
            })
        );
        return amountIn;
    }

    /* ========================================================================================= */
    /*                               NFT Position Manager Helpers                                */
    /* ========================================================================================= */

    /**
     * @dev Returns the current liquidity in a position represented by tokenId NFT
     */
    function getPositionLiquidity(address positionManager, uint256 tokenId)
        public
        view
        returns (uint128 liquidity)
    {
        (, , , , , , , liquidity, , , , ) = INonfungiblePositionManager(
            positionManager
        ).positions(tokenId);
    }

    /**
     * @dev Stake liquidity in position represented by tokenId NFT
     */
    function stake(
        uint256 amount0,
        uint256 amount1,
        address positionManager,
        uint256 tokenId
    ) public returns (uint256 stakedAmount0, uint256 stakedAmount1) {
        (, stakedAmount0, stakedAmount1) = INonfungiblePositionManager(
            positionManager
        ).increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: amount0,
                    amount1Desired: amount1,
                    amount0Min: amount0.sub(amount0.div(MINT_BURN_SLIPPAGE)),
                    amount1Min: amount1.sub(amount1.div(MINT_BURN_SLIPPAGE)),
                    deadline: block.timestamp
                })
            );
    }

    /**
     * @dev Unstakes a given amount of liquidity from the Uni V3 position
     * @param liquidity amount of liquidity to unstake
     * @return amount0 token0 amount unstaked
     * @return amount1 token1 amount unstaked
     */
    function unstakePosition(
        uint128 liquidity,
        PositionDetails memory positionDetails
    ) public returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager positionManager = INonfungiblePositionManager(
                positionDetails.positionManager
            );
        (uint256 _amount0, uint256 _amount1) = getAmountsForLiquidity(
            liquidity,
            positionDetails.priceLower,
            positionDetails.priceUpper,
            positionDetails.pool
        );
        (amount0, amount1) = positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: positionDetails.tokenId,
                liquidity: liquidity,
                amount0Min: _amount0,
                amount1Min: _amount1,
                deadline: block.timestamp
            })
        );
    }

    /**
     *  @dev Collect token amounts from pool position
     */
    function collectPosition(
        uint128 amount0,
        uint128 amount1,
        uint256 tokenId,
        address positionManager
    ) public returns (uint256 collected0, uint256 collected1) {
        (collected0, collected1) = INonfungiblePositionManager(positionManager)
            .collect(
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenId,
                    recipient: address(this),
                    amount0Max: amount0,
                    amount1Max: amount1
                })
            );
    }

    /**
     * @dev Creates the NFT token representing the pool position
     * @dev Mint initial liquidity
     */
    function createPosition(
        uint256 amount0,
        uint256 amount1,
        address positionManager,
        TokenDetails memory tokenDetails,
        PositionDetails memory positionDetails
    ) public returns (uint256 _tokenId) {
        (_tokenId, , , ) = INonfungiblePositionManager(positionManager).mint(
            INonfungiblePositionManager.MintParams({
                token0: tokenDetails.token0,
                token1: tokenDetails.token1,
                fee: positionDetails.poolFee,
                tickLower: getTickFromPrice(positionDetails.priceLower),
                tickUpper: getTickFromPrice(positionDetails.priceUpper),
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0.sub(amount0.div(MINT_BURN_SLIPPAGE)),
                amount1Min: amount1.sub(amount1.div(MINT_BURN_SLIPPAGE)),
                recipient: address(this),
                deadline: block.timestamp
            })
        );
    }

    /* ========================================================================================= */
    /*                                  CLR Helpers                                        */
    /* ========================================================================================= */

    /**
     * @notice Admin function to stake tokens
     * @dev used in case there's leftover tokens in the contract
     * @dev Function differs from adminStake in that
     * @dev it calculates token amounts to stake so as to have
     * @dev all or most of the tokens in the position, and
     * @dev no tokens in buffer balance ; swaps as necessary
     */
    function rebalance(
        TokenDetails memory tokenDetails,
        PositionDetails memory positionDetails
    ) public {
        (uint256 token0Balance, uint256 token1Balance) = getBufferTokenBalance(
            tokenDetails
        );
        token0Balance = getToken0AmountInNativeDecimals(
            token0Balance,
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier
        );
        token1Balance = getToken1AmountInNativeDecimals(
            token1Balance,
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier
        );
        (
            uint256 stakeAmount0,
            uint256 stakeAmount1
        ) = checkIfAmountsMatchAndSwap(
                token0Balance,
                token1Balance,
                positionDetails,
                tokenDetails
            );
        (token0Balance, token1Balance) = getBufferTokenBalance(tokenDetails);
        token0Balance = getToken0AmountInNativeDecimals(
            token0Balance,
            tokenDetails.token0Decimals,
            tokenDetails.token0DecimalMultiplier
        );
        token1Balance = getToken1AmountInNativeDecimals(
            token1Balance,
            tokenDetails.token1Decimals,
            tokenDetails.token1DecimalMultiplier
        );
        if (stakeAmount0 > token0Balance) {
            stakeAmount0 = token0Balance;
        }
        if (stakeAmount1 > token1Balance) {
            stakeAmount1 = token1Balance;
        }
        (uint256 amount0, uint256 amount1) = calculatePoolMintedAmounts(
            stakeAmount0,
            stakeAmount1,
            positionDetails.priceLower,
            positionDetails.priceUpper,
            positionDetails.pool
        );
        require(amount0 != 0 || amount1 != 0, "Rebalance amounts are 0");
        stake(
            amount0,
            amount1,
            positionDetails.positionManager,
            positionDetails.tokenId
        );
    }

    /**
     * @dev Check if token amounts match before attempting rebalance in CLR
     * @dev Uniswap contract requires deposits at a precise token ratio
     * @dev If they don't match, swap the tokens so as to deposit as much as possible
     * @param amount0ToMint how much token0 amount we want to deposit/withdraw
     * @param amount1ToMint how much token1 amount we want to deposit/withdraw
     */
    function checkIfAmountsMatchAndSwap(
        uint256 amount0ToMint,
        uint256 amount1ToMint,
        PositionDetails memory positionDetails,
        TokenDetails memory tokenDetails
    ) public returns (uint256 amount0, uint256 amount1) {
        (
            uint256 amount0Minted,
            uint256 amount1Minted
        ) = calculatePoolMintedAmounts(
                amount0ToMint,
                amount1ToMint,
                positionDetails.priceLower,
                positionDetails.priceUpper,
                positionDetails.pool
            );
        if (
            amount0Minted <
            amount0ToMint.sub(amount0ToMint.div(MINT_BURN_SLIPPAGE)) ||
            amount1Minted <
            amount1ToMint.sub(amount1ToMint.div(MINT_BURN_SLIPPAGE))
        ) {
            // calculate liquidity ratio =
            // minted liquidity / total pool liquidity
            // used to calculate swap impact in pool
            uint256 mintLiquidity = getLiquidityForAmounts(
                amount0ToMint,
                amount1ToMint,
                positionDetails.priceLower,
                positionDetails.priceUpper,
                positionDetails.pool
            );
            uint256 poolLiquidity = getPoolLiquidity(positionDetails.pool);
            int128 liquidityRatio = poolLiquidity == 0
                ? 0
                : int128(ABDKMath64x64.divuu(mintLiquidity, poolLiquidity));
            (amount0, amount1) = restoreTokenRatios(
                liquidityRatio,
                AmountsMinted({
                    amount0ToMint: amount0ToMint,
                    amount1ToMint: amount1ToMint,
                    amount0Minted: amount0Minted,
                    amount1Minted: amount1Minted
                }),
                tokenDetails,
                positionDetails
            );
        } else {
            (amount0, amount1) = (amount0ToMint, amount1ToMint);
        }
    }

    /**
     * @dev Swap tokens in CLR so as to keep a ratio which is required for
     * @dev depositing/withdrawing liquidity to/from Uniswap pool
     */
    function restoreTokenRatios(
        int128 liquidityRatio,
        AmountsMinted memory amountsMinted,
        TokenDetails memory tokenDetails,
        PositionDetails memory positionDetails
    ) private returns (uint256 amount0, uint256 amount1) {
        // after normalization, returned swap amount will be in wei representation
        uint256 swapAmount;
        bool swapDirection;
        {
            uint256 midPrice = getPoolPriceWithDecimals(
                positionDetails.pool,
                tokenDetails.token0Decimals,
                tokenDetails.token1Decimals
            );
            // Swap amount returned is always in asset 0 terms
            (swapAmount, swapDirection) = Utils.calculateSwapAmount(
                Utils.AmountsMinted({
                    amount0ToMint: getToken0AmountInWei(
                        amountsMinted.amount0ToMint,
                        tokenDetails.token0Decimals,
                        tokenDetails.token0DecimalMultiplier
                    ),
                    amount1ToMint: getToken1AmountInWei(
                        amountsMinted.amount1ToMint,
                        tokenDetails.token1Decimals,
                        tokenDetails.token1DecimalMultiplier
                    ),
                    amount0Minted: getToken0AmountInWei(
                        amountsMinted.amount0Minted,
                        tokenDetails.token0Decimals,
                        tokenDetails.token0DecimalMultiplier
                    ),
                    amount1Minted: getToken1AmountInWei(
                        amountsMinted.amount1Minted,
                        tokenDetails.token1Decimals,
                        tokenDetails.token1DecimalMultiplier
                    )
                }),
                liquidityRatio,
                midPrice
            );
            if (swapAmount == 0) {
                return (
                    amountsMinted.amount0ToMint,
                    amountsMinted.amount1ToMint
                );
            }
        }
        uint256 swapAmountWithSlippage = swapAmount.add(
            swapAmount.div(SWAP_SLIPPAGE)
        );

        (uint256 balance0, uint256 balance1) = getBufferTokenBalance(
            tokenDetails
        );

        if (swapDirection) {
            if (balance0 < swapAmountWithSlippage) {
                swapAmountWithSlippage = balance0;
            }
            // Swap tokens
            uint256 amountOut = swapToken0ForToken1(
                swapAmountWithSlippage,
                swapAmount,
                positionDetails,
                tokenDetails
            );
            amount0 = amountsMinted.amount0ToMint.sub(
                getToken0AmountInNativeDecimals(
                    swapAmount,
                    tokenDetails.token0Decimals,
                    tokenDetails.token0DecimalMultiplier
                )
            );
            // amountOut is already in native decimals
            amount1 = amountsMinted.amount1ToMint.add(amountOut);
        } else {
            uint256 midPrice = getPoolPriceWithDecimals(
                positionDetails.pool,
                tokenDetails.token0Decimals,
                tokenDetails.token1Decimals
            );
            swapAmountWithSlippage = swapAmountWithSlippage.mul(midPrice).div(
                1e12
            );
            if (balance1 < swapAmountWithSlippage) {
                swapAmountWithSlippage = balance1;
            }
            // Swap tokens
            uint256 amountIn = swapToken1ForToken0(
                swapAmountWithSlippage,
                swapAmount.mul(midPrice).div(1e12),
                positionDetails,
                tokenDetails
            );
            amount0 = amountsMinted.amount0ToMint.add(
                getToken0AmountInNativeDecimals(
                    swapAmount,
                    tokenDetails.token0Decimals,
                    tokenDetails.token0DecimalMultiplier
                )
            );
            // amountIn is already in native decimals
            amount1 = amountsMinted.amount1ToMint.sub(amountIn);
        }
    }

    /**
     * @dev Get token balances in CLR contract
     * @dev returned balances are in wei representation
     */
    function getBufferTokenBalance(TokenDetails memory tokenDetails)
        public
        view
        returns (uint256 amount0, uint256 amount1)
    {
        IERC20 token0 = IERC20(tokenDetails.token0);
        IERC20 token1 = IERC20(tokenDetails.token1);
        return (
            getBufferToken0Balance(
                token0,
                tokenDetails.token0Decimals,
                tokenDetails.token0DecimalMultiplier,
                tokenDetails.rewardAmountRemainingToken0
            ),
            getBufferToken1Balance(
                token1,
                tokenDetails.token1Decimals,
                tokenDetails.token1DecimalMultiplier,
                tokenDetails.rewardAmountRemainingToken1
            )
        );
    }

    /**
     * @dev Get token0 balance in CLR
     * @dev Accounts for reward token amount if it's same as token 0
     */
    function getBufferToken0Balance(
        IERC20 token0,
        uint8 token0Decimals,
        uint256 token0DecimalMultiplier,
        uint256 rewardAmountRemaining
    ) public view returns (uint256 amount0) {
        amount0 = getToken0AmountInWei(
            subZero(token0.balanceOf(address(this)), rewardAmountRemaining),
            token0Decimals,
            token0DecimalMultiplier
        );
    }

    /**
     * @dev Get token1 balance in CLR
     * @dev Accounts for reward token amount if it's same as token 1
     */
    function getBufferToken1Balance(
        IERC20 token1,
        uint8 token1Decimals,
        uint256 token1DecimalMultiplier,
        uint256 rewardAmountRemaining
    ) public view returns (uint256 amount1) {
        amount1 = getToken1AmountInWei(
            subZero(token1.balanceOf(address(this)), rewardAmountRemaining),
            token1Decimals,
            token1DecimalMultiplier
        );
    }

    /* ========================================================================================= */
    /*                                       Miscellaneous                                       */
    /* ========================================================================================= */

    /**
     * @dev Returns token0 amount in token0Decimals
     */
    function getToken0AmountInNativeDecimals(
        uint256 amount,
        uint8 token0Decimals,
        uint256 token0DecimalMultiplier
    ) public pure returns (uint256) {
        if (token0Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.div(token0DecimalMultiplier);
        }
        return amount;
    }

    /**
     * @dev Returns token1 amount in token1Decimals
     */
    function getToken1AmountInNativeDecimals(
        uint256 amount,
        uint8 token1Decimals,
        uint256 token1DecimalMultiplier
    ) public pure returns (uint256) {
        if (token1Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.div(token1DecimalMultiplier);
        }
        return amount;
    }

    /**
     * @dev Returns token0 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken0AmountInWei(
        uint256 amount,
        uint8 token0Decimals,
        uint256 token0DecimalMultiplier
    ) public pure returns (uint256) {
        if (token0Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.mul(token0DecimalMultiplier);
        }
        return amount;
    }

    /**
     * @dev Returns token1 amount in TOKEN_DECIMAL_REPRESENTATION
     */
    function getToken1AmountInWei(
        uint256 amount,
        uint8 token1Decimals,
        uint256 token1DecimalMultiplier
    ) public pure returns (uint256) {
        if (token1Decimals < TOKEN_DECIMAL_REPRESENTATION) {
            amount = amount.mul(token1DecimalMultiplier);
        }
        return amount;
    }

    /**
     * @dev get price from tick
     */
    function getSqrtRatio(int24 tick) public pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    /**
     * @dev get tick from price
     */
    function getTickFromPrice(uint160 price) public pure returns (int24) {
        return TickMath.getTickAtSqrtRatio(price);
    }

    /**
     * @dev Subtract two numbers and return absolute value
     */
    function subAbs(uint256 amount0, uint256 amount1)
        public
        pure
        returns (uint256)
    {
        return amount0 >= amount1 ? amount0.sub(amount1) : amount1.sub(amount0);
    }

    /**
     * @dev Subtract two numbers and return 0 if result is < 0
     */
    function subZero(uint256 amount0, uint256 amount1)
        public
        pure
        returns (uint256)
    {
        return amount0 >= amount1 ? amount0.sub(amount1) : 0;
    }
}