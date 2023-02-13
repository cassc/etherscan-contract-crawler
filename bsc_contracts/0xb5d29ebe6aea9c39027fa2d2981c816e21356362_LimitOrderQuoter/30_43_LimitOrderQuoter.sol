// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./LimitOrderSwapRouter.sol";
import "./lib/ConveyorTickMath.sol";
import "./interfaces/ILimitOrderQuoter.sol";

/// @title LimitOrderQuoter
/// @author 0xOsiris, 0xKitsune, Conveyor Labs
/// @notice This contract handles all CFMM quoting logic.
contract LimitOrderQuoter is ILimitOrderQuoter, ConveyorTickMath {
    address immutable WETH;
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant ZERO = 0;

    constructor(address _weth) {
        require(_weth != address(0), "Invalid weth address");
        WETH = _weth;
    }

    ///@notice Helper function to determine if a pool address is Uni V2 compatible.
    ///@param lp - Pair address.
    ///@return bool Indicator whether the pool is not Uni V3 compatible.
    function _lpIsNotUniV3(address lp) internal returns (bool) {
        bool success;
        assembly {
            //store the function sig for  "fee()"
            mstore(
                0x00,
                0xddca3f4300000000000000000000000000000000000000000000000000000000
            )

            success := call(
                gas(), // gas remaining
                lp, // destination address
                0, // no ether
                0x00, // input buffer (starts after the first 32 bytes in the `data` array)
                0x04, // input length (loaded from the first 32 bytes in the `data` array)
                0x00, // output buffer
                0x00 // output length
            )
        }
        ///@notice return the opposite of success, meaning if the call succeeded, the address is univ3, and we should
        ///@notice indicate that lpIsNotUniV3 is false
        return !success;
    }

    ///@notice Function to return the index of the best price in the executionPrices array.
    ///@param executionPrices - Array of execution prices to evaluate.
    ///@param buyOrder - Boolean indicating whether the order is a buy or sell.
    ///@return bestPriceIndex - Index of the best price in the executionPrices array.
    function findBestTokenToWethExecutionPrice(
        LimitOrderSwapRouter.TokenToWethExecutionPrice[]
            calldata executionPrices,
        bool buyOrder
    ) external pure returns (uint256 bestPriceIndex) {
        ///@notice If the order is a buy order, set the initial best price at 0.
        if (buyOrder) {
            uint256 bestPrice = MAX_UINT256;

            ///@notice For each exectution price in the executionPrices array.
            for (uint256 i = 0; i < executionPrices.length; ) {
                uint256 executionPrice = executionPrices[i].price;

                ///@notice If the execution price is better than the best exectuion price, update the bestPriceIndex.
                if (executionPrice < bestPrice && executionPrice != 0) {
                    bestPrice = executionPrice;
                    bestPriceIndex = i;
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            ///@notice If the order is a sell order, set the initial best price at max uint256.
            uint256 bestPrice = ZERO;
            for (uint256 i = 0; i < executionPrices.length; ) {
                uint256 executionPrice = executionPrices[i].price;

                ///@notice If the execution price is better than the best exectuion price, update the bestPriceIndex.
                if (executionPrice > bestPrice) {
                    bestPrice = executionPrice;
                    bestPriceIndex = i;
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    ///@notice Function to return the index of the best price in the executionPrices array.
    ///@param executionPrices - Array of execution prices to evaluate.
    ///@param buyOrder - Boolean indicating whether the order is a buy or sell.
    ///@return bestPriceIndex - Index of the best price in the executionPrices array.
    function findBestTokenToTokenExecutionPrice(
        LimitOrderSwapRouter.TokenToTokenExecutionPrice[]
            calldata executionPrices,
        bool buyOrder
    ) external pure returns (uint256 bestPriceIndex) {
        ///@notice If the order is a buy order, set the initial best price at type(uint256).max.
        if (buyOrder) {
            uint256 bestPrice = MAX_UINT256;
            ///@notice For each exectution price in the executionPrices array.
            for (uint256 i = 0; i < executionPrices.length; ) {
                uint256 executionPrice = executionPrices[i].price;
                ///@notice If the execution price is better than the best exectuion price, update the bestPriceIndex.
                if (executionPrice < bestPrice && executionPrice != 0) {
                    bestPrice = executionPrice;
                    bestPriceIndex = i;
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            uint256 bestPrice = ZERO;
            ///@notice If the order is a sell order, set the initial best price at max uint256.
            for (uint256 i = 0; i < executionPrices.length; ) {
                uint256 executionPrice = executionPrices[i].price;
                ///@notice If the execution price is better than the best exectuion price, update the bestPriceIndex.
                if (executionPrice > bestPrice) {
                    bestPrice = executionPrice;
                    bestPriceIndex = i;
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    ///@notice Initializes all routes from tokenA to Weth -> Weth to tokenB and returns an array of all combinations as ExectionPrice[]
    ///@param spotReserveAToWeth - Spot reserve of tokenA to Weth.
    ///@param lpAddressesAToWeth - Pair address of tokenA to Weth.
    function initializeTokenToWethExecutionPrices(
        LimitOrderSwapRouter.SpotReserve[] calldata spotReserveAToWeth,
        address[] calldata lpAddressesAToWeth
    )
        external
        pure
        returns (LimitOrderSwapRouter.TokenToWethExecutionPrice[] memory)
    {
        ///@notice Initialize a new TokenToWethExecutionPrice array to store prices.
        LimitOrderSwapRouter.TokenToWethExecutionPrice[]
            memory executionPrices = new LimitOrderSwapRouter.TokenToWethExecutionPrice[](
                spotReserveAToWeth.length
            );

        ///@notice Scoping to avoid stack too deep.
        {
            ///@notice For each spot reserve, initialize a token to weth execution price.
            for (uint256 i = 0; i < spotReserveAToWeth.length; ) {
                executionPrices[i] = LimitOrderSwapRouter
                    .TokenToWethExecutionPrice(
                        spotReserveAToWeth[i].res0,
                        spotReserveAToWeth[i].res1,
                        spotReserveAToWeth[i].spotPrice,
                        lpAddressesAToWeth[i]
                    );

                unchecked {
                    ++i;
                }
            }
        }

        return (executionPrices);
    }

    ///@notice Initializes all routes from tokenA to Weth -> Weth to tokenB and returns an array of all combinations as ExectionPrice[].
    ///@param tokenIn - Address of the token to swap from.
    ///@param spotReserveAToWeth - Spot reserve of tokenA to Weth.
    ///@param lpAddressesAToWeth - Pair address of tokenA to Weth.
    ///@param spotReserveWethToB - Spot reserve of Weth to tokenB.
    ///@param lpAddressesWethToB - Pair address of Weth to tokenB
    function initializeTokenToTokenExecutionPrices(
        address tokenIn,
        LimitOrderSwapRouter.SpotReserve[] calldata spotReserveAToWeth,
        address[] calldata lpAddressesAToWeth,
        LimitOrderSwapRouter.SpotReserve[] calldata spotReserveWethToB,
        address[] calldata lpAddressesWethToB
    )
        external
        view
        returns (LimitOrderSwapRouter.TokenToTokenExecutionPrice[] memory)
    {
        ///@notice Initialize a new TokenToTokenExecutionPrice array to store prices.
        LimitOrderSwapRouter.TokenToTokenExecutionPrice[]
            memory executionPrices = new LimitOrderSwapRouter.TokenToTokenExecutionPrice[](
                spotReserveAToWeth.length * spotReserveWethToB.length
            );

        ///@notice If TokenIn is Weth
        if (tokenIn == WETH) {
            ///@notice Iterate through each SpotReserve on Weth to TokenB
            for (uint256 i = 0; i < spotReserveWethToB.length; ) {
                ///@notice Then set res0, and res1 for tokenInToWeth to 0 and lpAddressAToWeth to the 0 address
                executionPrices[i] = LimitOrderSwapRouter
                    .TokenToTokenExecutionPrice(
                        0,
                        0,
                        spotReserveWethToB[i].res0,
                        spotReserveWethToB[i].res1,
                        spotReserveWethToB[i].spotPrice,
                        address(0),
                        lpAddressesWethToB[i]
                    );

                unchecked {
                    ++i;
                }
            }
        } else {
            ///@notice Initialize index to 0
            uint256 index = 0;
            ///@notice Iterate through each SpotReserve on TokenA to Weth
            for (uint256 i = 0; i < spotReserveAToWeth.length; ) {
                ///@notice Iterate through each SpotReserve on Weth to TokenB
                for (uint256 j = 0; j < spotReserveWethToB.length; ) {
                    ///@notice Calculate the spot price from tokenA to tokenB represented as 128.128 fixed point.
                    uint256 spotPriceFinal = uint256(
                        _calculateTokenToWethToTokenSpotPrice(
                            spotReserveAToWeth[i].spotPrice,
                            spotReserveWethToB[j].spotPrice
                        )
                    ) << 64;

                    ///@notice Set the executionPrices at index to TokenToTokenExecutionPrice
                    executionPrices[index] = LimitOrderSwapRouter
                        .TokenToTokenExecutionPrice(
                            spotReserveAToWeth[i].res0,
                            spotReserveAToWeth[i].res1,
                            spotReserveWethToB[j].res1,
                            spotReserveWethToB[j].res0,
                            spotPriceFinal,
                            lpAddressesAToWeth[i],
                            lpAddressesWethToB[j]
                        );
                    ///@notice Increment the index
                    unchecked {
                        ++index;
                    }

                    unchecked {
                        ++j;
                    }
                }

                unchecked {
                    ++i;
                }
            }
        }

        return (executionPrices);
    }

    ///@notice Function to simulate the TokenToToken price change on a pair.
    ///@param alphaX - The input quantity to simulate the price change on.
    ///@param executionPrice - The TokenToTokenExecutionPrice to simulate the price change on.
    function simulateTokenToTokenPriceChange(
        uint128 alphaX,
        LimitOrderSwapRouter.TokenToTokenExecutionPrice memory executionPrice
    )
        external
        returns (LimitOrderSwapRouter.TokenToTokenExecutionPrice memory)
    {
        ///@notice Check if the reserves are set to 0. This indicates if the tokenPair is Weth to TokenOut if true.
        if (
            executionPrice.aToWethReserve0 != 0 &&
            executionPrice.aToWethReserve1 != 0
        ) {
            ///@notice Initialize variables to prevent stack too deep
            address pool = executionPrice.lpAddressAToWeth;
            address token0;
            address token1;
            bool _isUniV2 = _lpIsNotUniV3(pool);
            ///@notice Scope to prevent stack too deep.
            {
                ///@notice Check if the pool is Uni V2 and get the token0 and token1 address.
                if (_isUniV2) {
                    token0 = IUniswapV2Pair(pool).token0();
                    token1 = IUniswapV2Pair(pool).token1();
                } else {
                    token0 = IUniswapV3Pool(pool).token0();
                    token1 = IUniswapV3Pool(pool).token1();
                }
            }

            ///@notice Get the tokenIn decimals
            uint8 tokenInDecimals = token1 == WETH
                ? IERC20(token0).decimals()
                : IERC20(token1).decimals();

            ///@notice Convert to 18 decimals to have correct price change on the reserve quantities in common 18 decimal form.
            uint128 amountIn = tokenInDecimals <= 18
                ? uint128(alphaX * 10**(18 - tokenInDecimals))
                : uint128(alphaX / (10**(tokenInDecimals - 18)));

            ///@notice Abstracted function call to simulate the token to token price change on the common decimal amountIn
            executionPrice = _simulateTokenToTokenPriceChange(
                amountIn,
                executionPrice
            );
        } else {
            ///@notice Abstracted function call to simulate the weth to token price change on the common decimal amountIn
            executionPrice = _simulateWethToTokenPriceChange(
                alphaX,
                executionPrice
            );
        }

        return executionPrice;
    }

    ///@notice Function to simulate the TokenToToken price change on a pair.
    ///@param alphaX - The input quantity to simulate the price change on.
    ///@param executionPrice - The TokenToTokenExecutionPrice to simulate the price change on.
    function _simulateTokenToTokenPriceChange(
        uint128 alphaX,
        LimitOrderSwapRouter.TokenToTokenExecutionPrice memory executionPrice
    )
        internal
        returns (LimitOrderSwapRouter.TokenToTokenExecutionPrice memory)
    {
        ///@notice Retrive the new simulated spot price, reserve values, and amount out on the TokenIn To Weth pool
        (
            uint256 newSpotPriceA,
            uint128 newReserveAToken,
            uint128 newReserveAWeth,
            uint128 amountOut
        ) = _simulateAToWethPriceChange(alphaX, executionPrice);

        ///@notice Retrive the new simulated spot price, and reserve values on the Weth to tokenOut pool.
        ///@notice Use the amountOut value from the previous simulation as the amountIn on the current simulation.
        (
            uint256 newSpotPriceB,
            uint128 newReserveBToken,
            uint128 newReserveBWeth
        ) = _simulateWethToBPriceChange(amountOut, executionPrice);

        {
            ///@notice Calculate the new spot price over both swaps from the simulated values.
            uint256 newTokenToTokenSpotPrice = uint256(
                ConveyorMath.mul64x64(
                    uint128(newSpotPriceA >> 64),
                    uint128(newSpotPriceB >> 64)
                )
            ) << 64;

            ///@notice Update executionPrice to the simulated values, and return executionPrice.
            executionPrice.price = newTokenToTokenSpotPrice;
            executionPrice.aToWethReserve0 = newReserveAToken;
            executionPrice.aToWethReserve1 = newReserveAWeth;
            executionPrice.wethToBReserve0 = newReserveBWeth;
            executionPrice.wethToBReserve1 = newReserveBToken;
        }
        return executionPrice;
    }

    ///@notice Function to simulate the AToWeth price change on a pair.
    ///@param alphaX - The input quantity to simulate the price change on.
    ///@param executionPrice - The TokenToTokenExecutionPrice to simulate the price change on.
    function _simulateAToWethPriceChange(
        uint128 alphaX,
        LimitOrderSwapRouter.TokenToTokenExecutionPrice memory executionPrice
    )
        internal
        returns (
            uint256 newSpotPriceA,
            uint128 newReserveAToken,
            uint128 newReserveAWeth,
            uint128 amountOut
        )
    {
        ///@notice Cache the Reserves and the pool address on the liquidity pool
        uint128 reserveAToken = executionPrice.aToWethReserve0;
        uint128 reserveAWeth = executionPrice.aToWethReserve1;
        address poolAddressAToWeth = executionPrice.lpAddressAToWeth;

        ///@notice Simulate the price change from TokenIn To Weth and return the values.
        (
            newSpotPriceA,
            newReserveAToken,
            newReserveAWeth,
            amountOut
        ) = _simulateAToBPriceChange(
            alphaX,
            reserveAToken,
            reserveAWeth,
            poolAddressAToWeth,
            true
        );
    }

    ///@notice Function to simulate the WethToToken price change on a pair.
    ///@param alphaX - The input quantity to simulate the price change on.
    ///@param executionPrice - The TokenToTokenExecutionPrice to simulate the price change on.
    function _simulateWethToTokenPriceChange(
        uint128 alphaX,
        LimitOrderSwapRouter.TokenToTokenExecutionPrice memory executionPrice
    )
        internal
        returns (LimitOrderSwapRouter.TokenToTokenExecutionPrice memory)
    {
        ///@notice Cache the Weth and TokenOut reserves
        uint128 reserveBWeth = executionPrice.wethToBReserve0;
        uint128 reserveBToken = executionPrice.wethToBReserve1;

        ///@notice Cache the pool address
        address poolAddressWethToB = executionPrice.lpAddressWethToB;

        ///@notice Get the simulated spot price and reserve values.
        (
            uint256 newSpotPriceB,
            uint128 newReserveBWeth,
            uint128 newReserveBToken,

        ) = _simulateAToBPriceChange(
                alphaX,
                reserveBWeth,
                reserveBToken,
                poolAddressWethToB,
                false
            );

        ///@notice Update TokenToTokenExecutionPrice to the new simulated values.
        executionPrice.price = newSpotPriceB;
        executionPrice.aToWethReserve0 = 0;
        executionPrice.aToWethReserve1 = 0;
        executionPrice.wethToBReserve0 = newReserveBWeth;
        executionPrice.wethToBReserve1 = newReserveBToken;

        return executionPrice;
    }

    ///@notice Function to simulate the WethToB price change on a pair.
    ///@param alphaX - The input quantity to simulate the price change on.
    ///@param executionPrice - The TokenToTokenExecutionPrice to simulate the price change on.
    function _simulateWethToBPriceChange(
        uint128 alphaX,
        LimitOrderSwapRouter.TokenToTokenExecutionPrice memory executionPrice
    )
        internal
        returns (
            uint256 newSpotPriceB,
            uint128 newReserveBWeth,
            uint128 newReserveBToken
        )
    {
        ///@notice Cache the reserve values, and the pool address on the token pair.
        uint128 reserveBWeth = executionPrice.wethToBReserve0;
        uint128 reserveBToken = executionPrice.wethToBReserve1;
        address poolAddressWethToB = executionPrice.lpAddressWethToB;

        ///@notice Simulate the Weth to TokenOut price change and return the values.
        (
            newSpotPriceB,
            newReserveBWeth,
            newReserveBToken,

        ) = _simulateAToBPriceChange(
            alphaX,
            reserveBToken,
            reserveBWeth,
            poolAddressWethToB,
            false
        );
    }

    /// @notice Function to calculate the price change of a token pair on a specified input quantity.
    /// @param alphaX Quantity to be added into the TokenA reserves
    /// @param reserveA Reserves of tokenA
    /// @param reserveB Reserves of tokenB
    function _simulateAToBPriceChange(
        uint128 alphaX,
        uint128 reserveA,
        uint128 reserveB,
        address pool,
        bool isTokenToWeth
    )
        internal
        returns (
            uint256,
            uint128,
            uint128,
            uint128
        )
    {
        ///@notice Initialize Array to hold the simulated reserve quantities.
        uint128[] memory newReserves = new uint128[](2);

        ///@notice If the liquidity pool is not Uniswap V3 then the calculation is different.
        if (_lpIsNotUniV3(pool)) {
            unchecked {
                ///@notice Supply alphaX to the tokenA reserves.
                uint256 denominator = reserveA + alphaX;

                ///@notice Numerator is the new tokenB reserve quantity i.e k/(reserveA+alphaX)
                uint256 numerator = FullMath.mulDiv(
                    uint256(reserveA),
                    uint256(reserveB),
                    denominator
                );

                ///@notice Spot price = reserveB/reserveA
                uint256 spotPrice = uint256(
                    ConveyorMath.divUU(numerator, denominator)
                ) << 64;

                ///@notice Update update the new reserves array to the simulated reserve values.
                newReserves[0] = uint128(denominator);
                newReserves[1] = uint128(numerator);

                ///@notice Set the amountOut of the swap on alphaX input amount.
                uint128 amountOut = uint128(
                    getAmountOut(alphaX, reserveA, reserveB)
                );

                return (spotPrice, newReserves[0], newReserves[1], amountOut);
            }
            ///@notice If the liquidity pool is Uniswap V3.
        } else {
            ///@notice Get the Uniswap V3 spot price change and amountOut from the simuulating alphaX on the pool.
            (
                uint128 spotPrice64x64,
                uint128 amountOut
            ) = calculateNextSqrtPriceX96(isTokenToWeth, pool, alphaX);

            ///@notice Set the reserves to 0 since they are not required for Uniswap V3
            newReserves[0] = 0;
            newReserves[1] = 0;

            ///@notice Left shift 64 to adjust spot price to 128.128 fixed point
            uint256 spotPrice = uint256(spotPrice64x64) << 64;

            return (spotPrice, newReserves[0], newReserves[1], amountOut);
        }
    }

    ///@notice Function to get the amountOut from a UniV2 lp.
    ///@param amountIn - AmountIn for the swap.
    ///@param reserveIn - tokenIn reserve for the swap.
    ///@param reserveOut - tokenOut reserve for the swap.
    ///@return amountOut - AmountOut from the given parameters.
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) {
            revert InsufficientInputAmount(0, 1);
        }

        if (reserveIn == 0) {
            revert InsufficientLiquidity();
        }

        if (reserveOut == 0) {
            revert InsufficientLiquidity();
        }

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + (amountInWithFee);
        amountOut = numerator / denominator;
    }

    ///@notice Function to simulate the price change from TokanA to Weth on an amount into the pool
    ///@param alphaX The amount supplied to the TokenA reserves of the pool.
    ///@param executionPrice The TokenToWethExecutionPrice to simulate the price change on.
    function simulateTokenToWethPriceChange(
        uint128 alphaX,
        LimitOrderSwapRouter.TokenToWethExecutionPrice memory executionPrice
    ) external returns (LimitOrderSwapRouter.TokenToWethExecutionPrice memory) {
        ///@notice Cache the liquidity pool address
        address pool = executionPrice.lpAddressAToWeth;

        ///@notice Cache token0 and token1 from the pool address
        address token0 = IUniswapV2Pair(pool).token0();
        address token1 = IUniswapV2Pair(pool).token1();

        ///@notice Get the decimals of the tokenIn on the swap
        uint8 tokenInDecimals = token1 == WETH
            ? IERC20(token0).decimals()
            : IERC20(token1).decimals();

        ///@notice Convert to 18 decimals to have correct price change on the reserve quantities in common 18 decimal form
        uint128 amountIn = tokenInDecimals <= 18
            ? uint128(alphaX * 10**(18 - tokenInDecimals))
            : uint128(alphaX / (10**(tokenInDecimals - 18)));

        ///@notice Simulate the price change on the 18 decimal amountIn quantity, and set executionPrice struct to the updated quantities.
        (
            executionPrice.price,
            executionPrice.aToWethReserve0,
            executionPrice.aToWethReserve1,

        ) = _simulateAToBPriceChange(
            amountIn,
            executionPrice.aToWethReserve0,
            executionPrice.aToWethReserve1,
            pool,
            true
        );

        return executionPrice;
    }

    ///@notice Helper function to calculate precise price change in a uni v3 pool after alphaX value is added to the liquidity on either token
    ///@param isTokenToWeth boolean indicating whether swap is happening from token->weth or weth->token respectively
    ///@param pool address of the Uniswap v3 pool to simulate the price change on
    ///@param alphaX quantity to be added to the liquidity of tokenIn
    ///@return spotPrice 64.64 fixed point spot price after the input quantity has been added to the pool
    ///@return amountOut quantity recieved on the out token post swap
    function calculateNextSqrtPriceX96(
        bool isTokenToWeth,
        address pool,
        uint256 alphaX
    ) internal view returns (uint128 spotPrice, uint128 amountOut) {
        ///@notice Concentrated liquidity in current price tick range
        uint128 liquidity = IUniswapV3Pool(pool).liquidity();

        ///@notice Get token0/token1 from the pool
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();

        ///@notice Boolean indicating whether weth is token0 or token1
        bool wethIsToken0 = token0 == WETH ? true : false;

        ///@notice Cache pool fee
        uint24 fee = IUniswapV3Pool(pool).fee();

        uint160 price;
        int24 tickSpacing = IUniswapV3Pool(pool).tickSpacing();

        if (isTokenToWeth) {
            (amountOut, price) = simulateAmountOutOnSqrtPriceX96(
                wethIsToken0 ? token0 : token1,
                wethIsToken0 ? token1 : token0,
                pool,
                alphaX,
                tickSpacing,
                liquidity,
                fee
            );
        } else {
            (amountOut, price) = simulateAmountOutOnSqrtPriceX96(
                wethIsToken0 ? token0 : token1,
                wethIsToken0 ? token0 : token1,
                pool,
                alphaX,
                tickSpacing,
                liquidity,
                fee
            );
        }
        spotPrice = uint128(
            fromSqrtX96(price, wethIsToken0, token0, token1) >> 64
        );
    }

    ///@notice Helper function to calculate amountOutMin value agnostically across dexes on the first hop from tokenA to WETH.
    ///@param lpAddressAToWeth - The liquidity pool for tokenA to Weth.
    ///@param amountInOrder - The amount in on the swap.
    ///@param taxIn - The tax on the input token for the swap.
    ///@param feeIn - The fee on the swap.
    ///@param tokenIn - The address of tokenIn on the swap.
    ///@return amountOutMinAToWeth - The amountOutMin in the swap.
    function calculateAmountOutMinAToWeth(
        address lpAddressAToWeth,
        uint256 amountInOrder,
        uint16 taxIn,
        uint24 feeIn,
        address tokenIn
    ) external returns (uint256 amountOutMinAToWeth) {
        ///@notice Check if the lp is UniV3
        if (!_lpIsNotUniV3(lpAddressAToWeth)) {
            ///@notice 1000==100% so divide amountInOrder *taxIn by 10**5 to adjust to correct base
            ///@dev If the token is taxed there will be a transfer fee when the tokens are sent to the pool. So, decrement the amountIn on the swap by the amountIn - tokenTax
            uint256 amountInBuffer = (amountInOrder * taxIn) / 10**5;
            uint256 amountIn = amountInOrder - amountInBuffer;
            ///@notice Get token0 in the pool.
            address token0 = IUniswapV3Pool(lpAddressAToWeth).token0();

            ///@notice Get the liqudiity and tick spacing storage variables from the pool.
            uint128 liquidity = IUniswapV3Pool(lpAddressAToWeth).liquidity();
            int24 tickSpacing = IUniswapV3Pool(lpAddressAToWeth).tickSpacing();

            ///@notice Negate the simulated amount and convert to an unsigned integer.
            (amountOutMinAToWeth, ) = ConveyorTickMath
                .simulateAmountOutOnSqrtPriceX96(
                    token0,
                    tokenIn,
                    lpAddressAToWeth,
                    amountIn,
                    tickSpacing,
                    liquidity,
                    feeIn
                );
        } else {
            ///@notice Otherwise if the lp is a UniV2 LP.

            ///@notice Get the reserves from the pool.
            (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(
                lpAddressAToWeth
            ).getReserves();

            ///@notice Initialize the reserve0 and reserve1 depending on if Weth is token0 or token1.
            if (WETH == IUniswapV2Pair(lpAddressAToWeth).token0()) {
                uint256 amountInBuffer = (amountInOrder * taxIn) / 10**5;

                uint256 amountIn = amountInOrder - amountInBuffer;
                amountOutMinAToWeth = getAmountOut(
                    amountIn,
                    uint256(reserve1),
                    uint256(reserve0)
                );
            } else {
                uint256 amountInBuffer = (amountInOrder * taxIn) / 10**5;

                uint256 amountIn = amountInOrder - amountInBuffer;
                amountOutMinAToWeth = getAmountOut(
                    amountIn,
                    uint256(reserve0),
                    uint256(reserve1)
                );
            }
        }
    }

    ///@notice Helper to calculate the multiplicative spot price over both router hops
    ///@param spotPriceAToWeth spotPrice of Token A relative to Weth
    ///@param spotPriceWethToB spotPrice of Weth relative to Token B
    ///@return spotPriceFinal multiplicative finalSpot
    function _calculateTokenToWethToTokenSpotPrice(
        uint256 spotPriceAToWeth,
        uint256 spotPriceWethToB
    ) internal pure returns (uint128 spotPriceFinal) {
        spotPriceFinal = ConveyorMath.mul64x64(
            uint128(spotPriceAToWeth >> 64),
            uint128(spotPriceWethToB >> 64)
        );
    }
}