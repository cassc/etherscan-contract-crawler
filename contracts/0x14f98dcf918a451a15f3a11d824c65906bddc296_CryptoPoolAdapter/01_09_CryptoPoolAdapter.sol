// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Treasury.sol";
import "./interfaces/ICryptoPool.sol";


contract CryptoPoolAdapter is Ownable {

    /**
     * @dev Adds liquidity to the pool.
     *
     * @param pool Address of the pool contract;
     * @param amountIn Amount of input token to add as liquidity;
     * @param coinIndex Index of the input token;
     * @param to Address where the LP tokens will be transferred;
     * @param minAmountOut Minimum amount of coin to receive;
     * @param emergencyTo Emergency to address in case of inconsistency.
     */
    function addLiquidity(
        address pool,
        uint256 amountIn,
        uint256 coinIndex,
        address to,
        uint256 minAmountOut,
        address emergencyTo
    ) external returns(uint256 amountOut) {
        address tokenIn = ICryptoPool(pool).coins(coinIndex);
        IERC20 erc20Impl = IERC20(tokenIn);
        SafeERC20.safeIncreaseAllowance(erc20Impl, pool, amountIn);

        uint256[2] memory amounts;
        amounts[coinIndex] = amountIn;
        uint256 minAmount = ICryptoPool(pool).calc_token_amount(amounts);
        if (minAmountOut > minAmount) {
            SafeERC20.safeTransfer(erc20Impl, emergencyTo, amountIn);
            return 0;
        }
        ICryptoPool(pool).add_liquidity(amounts, 0);

        address lp = ICryptoPool(pool).token();
        amountOut = IERC20(lp).balanceOf(address(this));
        require(amountOut >= minAmountOut, "CryptoPoolAdapter: min amount");

        if (to != address(this)) {
            SafeERC20.safeTransfer(
                IERC20(lp),
                to,
                amountOut
            );
        }
    }

    /**
     * @dev Swaps tokens in the pool.
     *
     * @param tokenIn Address of the token to swap;
     * @param pool Address of the pool contract;
     * @param i Index of the input token;
     * @param j Index of the output token;
     * @param tokenOut Address of the token to receive;
     * @param to Address where the output tokens will be transferred;
     * @param minAmountOut Minimum amount of coin to receive;
     * @param emergencyTo Emergency to address in case of inconsistency;
     * @param aggregationFee swap fee.
     */
    function swap(
        address tokenIn,
        address pool,
        uint256 i,
        uint256 j,
        address tokenOut,
        address to,
        uint256 minAmountOut,
        address emergencyTo,
        uint256 aggregationFee
    ) external returns(uint256 amountOut) {
        IERC20 erc20Impl = IERC20(tokenIn);

        uint256 amountIn = erc20Impl.balanceOf(address(this));

        uint256 minDy = ICryptoPool(pool).get_dy(i, j, amountIn);
        if (minAmountOut > minDy) {
            SafeERC20.safeTransfer(erc20Impl, emergencyTo, amountIn);
            return 0;
        }

        SafeERC20.safeIncreaseAllowance(erc20Impl, pool, amountIn);
        ICryptoPool(pool).exchange(i, j, amountIn, minDy);

        amountOut = IERC20(tokenOut).balanceOf(address(this));

        if (to != address(this)) {
            SafeERC20.safeTransfer(IERC20(tokenOut), to, amountOut);
        }
    }

    /**
     * @dev Removes liquidity from the pool.
     *
     * @param pool Address of the pool contract;
     * @param i Index of the LP token to burn;
     * @param to Address where the output token will be transferred;
     * @param tokenOut Address of the output token to receive;
     * @param minAmountOut Minimum amount of coin to receive;
     * @param emergencyTo Emergency to address in case of inconsistency.
     */
    function removeLiquidity(
        address pool,
        uint256 i,
        address to,
        address tokenOut,
        uint256 minAmountOut,
        address emergencyTo
    ) external returns(uint256 amountOut) {
        address lp = ICryptoPool(pool).token();
        IERC20 erc20Impl = IERC20(lp);
        uint256 amountIn = erc20Impl.balanceOf(address(this));
        SafeERC20.safeIncreaseAllowance(erc20Impl, pool, amountIn);
        uint256 minAmount = ICryptoPool(pool).calc_withdraw_one_coin(amountIn, i);
        if (minAmountOut > minAmount) {
            SafeERC20.safeTransfer(erc20Impl, emergencyTo, amountIn);
            return 0;
        }
        ICryptoPool(pool).remove_liquidity_one_coin(amountIn, i, 0);
        amountOut = IERC20(tokenOut).balanceOf(address(this));
        if (to != address(this)) {
            SafeERC20.safeTransfer(IERC20(tokenOut), to, amountOut);
        }
    }

}