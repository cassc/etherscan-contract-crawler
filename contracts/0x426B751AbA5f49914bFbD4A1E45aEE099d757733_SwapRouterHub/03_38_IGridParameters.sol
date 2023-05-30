// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IGridParameters {
    /// @dev Parameters for initializing the grid
    struct InitializeParameters {
        /// @dev The initial price of the grid, as a Q64.96.
        /// Price is represented as an amountToken1/amountToken0 Q64.96 value.
        uint160 priceX96;
        /// @dev The address to receive orders
        address recipient;
        /// @dev Represents the order parameters for token0
        BoundaryLowerWithAmountParameters[] orders0;
        /// @dev Represents the order parameters for token1
        BoundaryLowerWithAmountParameters[] orders1;
    }

    /// @dev Parameters for placing an order
    struct PlaceOrderParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    struct PlaceOrderInBatchParameters {
        /// @dev The address to receive the order
        address recipient;
        /// @dev When zero is true, it represents token0, otherwise it represents token1
        bool zero;
        BoundaryLowerWithAmountParameters[] orders;
    }

    struct BoundaryLowerWithAmountParameters {
        /// @dev The lower boundary of the order
        int24 boundaryLower;
        /// @dev The amount of token0 or token1 to add
        uint128 amount;
    }

    /// @dev Status during swap
    struct SwapState {
        /// @dev When true, token0 is swapped for token1, otherwise token1 is swapped for token0
        bool zeroForOne;
        /// @dev The remaining amount of the swap, which implicitly configures
        /// the swap as exact input (positive), or exact output (negative)
        int256 amountSpecifiedRemaining;
        /// @dev The calculated amount to be inputted
        uint256 amountInputCalculated;
        /// @dev The calculated amount of fee to be inputted
        uint256 feeAmountInputCalculated;
        /// @dev The calculated amount to be outputted
        uint256 amountOutputCalculated;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
        uint160 priceLimitX96;
        /// @dev The boundary of the grid
        int24 boundary;
        /// @dev The lower boundary of the grid
        int24 boundaryLower;
        uint160 initializedBoundaryLowerPriceX96;
        uint160 initializedBoundaryUpperPriceX96;
        /// @dev Whether the swap has been completed
        bool stopSwap;
    }

    struct SwapForBoundaryState {
        /// @dev The price indicated by the lower boundary, as a Q64.96
        uint160 boundaryLowerPriceX96;
        /// @dev The price indicated by the upper boundary, as a Q64.96
        uint160 boundaryUpperPriceX96;
        /// @dev The price indicated by the lower or upper boundary, as a Q64.96.
        /// When using token0 to exchange token1, it is equal to boundaryLowerPriceX96,
        /// otherwise it is equal to boundaryUpperPriceX96
        uint160 boundaryPriceX96;
        /// @dev The price of the grid, as a Q64.96
        uint160 priceX96;
    }

    struct UpdateBundleForTakerParameters {
        /// @dev The amount to be swapped in to bundle0
        uint256 amountInUsed;
        /// @dev The remaining amount to be swapped in to bundle1
        uint256 amountInRemaining;
        /// @dev The amount to be swapped out to bundle0
        uint128 amountOutUsed;
        /// @dev The remaining amount to be swapped out to bundle1
        uint128 amountOutRemaining;
        /// @dev The amount to be paid to bundle0
        uint128 takerFeeForMakerAmountUsed;
        /// @dev The amount to be paid to bundle1
        uint128 takerFeeForMakerAmountRemaining;
    }
}