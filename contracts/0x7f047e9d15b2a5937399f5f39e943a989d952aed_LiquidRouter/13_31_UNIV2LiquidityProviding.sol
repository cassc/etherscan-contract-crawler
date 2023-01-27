// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {IFraxRouter} from "src/interfaces/IFraxRouter.sol";
import {TokenUtils, Constants} from "src/common/TokenUtils.sol";

/// @title UNIV2LiquidityProviding
/// @notice Enables to add/remove liquidity to/from the Frax Router.
abstract contract UNIV2LiquidityProviding {
    /// @notice Frax Router contract address.
    address internal constant FRAX_ROUTER = 0xC14d550632db8592D1243Edc8B95b0Ad06703867;

    /// @notice Sushi Router contract address.
    address internal constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    modifier onlyValidRouter(address router) {
        if (router != FRAX_ROUTER && router != SUSHI_ROUTER) revert Constants.NOT_ALLOWED();
        _;
    }

    /// @notice Adds liquidity to the UNIV2 Router.
    /// @param tokenA Token A address.
    /// @param tokenB Token B address.
    /// @param amountADesired Amount of token A to add.
    /// @param amountBDesired Amount of token B to add.
    /// @param amountAMin Minimum amount of token A to add.
    /// @param amountBMin Minimum amount of token B to add.
    /// @param recipient Recipient address.
    /// @param deadline Deadline timestamp.
    function addLiquidity(
        address router,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address recipient,
        uint256 deadline
    ) external onlyValidRouter(router) {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        amountADesired = TokenUtils._amountIn(amountADesired, tokenA);
        amountBDesired = TokenUtils._amountIn(amountBDesired, tokenB);

        if (amountADesired != 0) TokenUtils._approve(tokenA, FRAX_ROUTER);
        if (amountBDesired != 0) TokenUtils._approve(tokenB, FRAX_ROUTER);

        IFraxRouter(FRAX_ROUTER).addLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, recipient, deadline
        );
    }

    /// @notice Removes liquidity from the Frax Router.
    /// @param tokenA Token A address.
    /// @param tokenB Token B address.
    /// @param lpToken LP token address.
    /// @param liquidity Amount of LP token to remove.
    /// @param amountAMin Minimum amount of token A to remove.
    /// @param amountBMin Minimum amount of token B to remove.
    /// @param recipient Recipient address.
    /// @param deadline Deadline timestamp.
    function removeLiquidity(
        address router,
        address tokenA,
        address tokenB,
        address lpToken,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address recipient,
        uint256 deadline
    ) external onlyValidRouter(router) {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        liquidity = TokenUtils._amountIn(liquidity, lpToken);
        if (liquidity != 0) TokenUtils._approve(lpToken, FRAX_ROUTER);

        IFraxRouter(FRAX_ROUTER).removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, recipient, deadline);
    }
}