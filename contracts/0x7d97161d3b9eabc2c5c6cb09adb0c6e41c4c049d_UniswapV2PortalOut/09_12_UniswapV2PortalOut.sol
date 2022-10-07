/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Uniswap V2-like pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV2.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router.sol";
import "./interface/IUniswapV2Pair.sol";
import "../interface/IPortalRegistry.sol";

contract UniswapV2PortalOut is PortalBaseV2 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    uint256 internal constant DEADLINE = type(uint256).max;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    /// Thrown when insufficient buyAmount is received after withdrawal
    /// @param buyAmount The amount of tokens received
    /// @param minBuyAmount The minimum acceptable quantity of buyAmount
    error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV2(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Remove liquidity from Uniswap V2-like pools into network tokens/ERC20 tokens
    /// @param sellToken The pool (i.e. pair) address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the swaps
    /// @param data  The encoded calls for the buyToken swaps
    /// @param partner The front end operator address
    /// @param router The router belonging to the protocol from which to remove liquidity
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes[] calldata data,
        address partner,
        IUniswapV2Router02 router
    ) external pausable returns (uint256 buyAmount) {
        sellAmount = _transferFromCaller(sellToken, sellAmount);

        buyAmount = _remove(
            sellToken,
            sellAmount,
            buyToken,
            target,
            data,
            router
        );

        buyAmount = _getFeeAmount(buyAmount);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Removes both tokens from the pool and swaps for buyToken
    /// @param sellToken The pair address (i.e. the LP address)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param sellAmount The quantity of LP tokens to remove from the pool
    /// @param target The excecution target for the swaps
    /// @param data  The encoded calls for the buyToken swaps
    /// @param router The router belonging to the protocol from which to remove liquidity
    /// @return buyAmount The quantity of buyToken acquired
    function _remove(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        address target,
        bytes[] calldata data,
        IUniswapV2Router02 router
    ) internal returns (uint256 buyAmount) {
        IUniswapV2Pair pair = IUniswapV2Pair(sellToken);

        _approve(sellToken, address(router), sellAmount);

        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 token0Amount = _getBalance(address(this), token0);
        uint256 token1Amount = _getBalance(address(this), token1);

        router.removeLiquidity(
            token0,
            token1,
            sellAmount,
            1,
            1,
            address(this),
            DEADLINE
        );

        token0Amount = _getBalance(address(this), token0) - token0Amount;
        token1Amount = _getBalance(address(this), token1) - token1Amount;

        buyAmount = _execute(token0, token0Amount, buyToken, target, data[0]);
        buyAmount += _execute(token1, token1Amount, buyToken, target, data[1]);
    }
}