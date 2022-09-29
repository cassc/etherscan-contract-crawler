/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Uniswap V2-like pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV2.sol";
import "./interface/Babylonian.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router.sol";
import "./interface/IUniswapV2Pair.sol";
import "../interface/IPortalRegistry.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract UniswapV2PortalIn is PortalBaseV2 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

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

    /// @notice Add liquidity to Uniswap V2-like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be one of the pool tokens)
    /// @param buyToken The pool (i.e. pair) address
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param router The Uniswap V2-like router to be used for adding liquidity
    /// @param returnResidual Return residual, if any, that remains
    /// following the deposit. Note: Probably a waste of gas to set to true
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        IUniswapV2Router02 router,
        bool returnResidual
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        buyAmount = _deposit(
            intermediateToken,
            amount,
            buyToken,
            router,
            returnResidual
        );

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Sets up the correct token ratio and deposits into the pool
    /// @param sellToken The token address to swap from
    /// @param sellAmount The quantity of tokens to sell
    /// @param buyToken The pool (i.e. pair) address
    /// @param router The router belonging to the protocol to add liquidity to
    /// @param returnResidual Return residual, if any, that remains
    /// following the deposit. Note: Probably a waste of gas to set to true
    /// @return liquidity The quantity of LP tokens acquired
    function _deposit(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        IUniswapV2Router02 router,
        bool returnResidual
    ) internal returns (uint256 liquidity) {
        IUniswapV2Pair pair = IUniswapV2Pair(buyToken);

        (uint256 res0, uint256 res1, ) = pair.getReserves();

        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 token0Amount;
        uint256 token1Amount;

        if (sellToken == token0) {
            uint256 swapAmount = _getSwapAmount(res0, sellAmount);
            if (swapAmount <= 0) swapAmount = sellAmount / 2;

            token1Amount = _intraSwap(
                sellToken,
                swapAmount,
                pair.token1(),
                router
            );

            token0Amount = sellAmount - swapAmount;
        } else {
            uint256 swapAmount = _getSwapAmount(res1, sellAmount);
            if (swapAmount <= 0) swapAmount = sellAmount / 2;

            token0Amount = _intraSwap(sellToken, swapAmount, token0, router);

            token1Amount = sellAmount - swapAmount;
        }
        liquidity = _addLiquidity(
            buyToken,
            token0,
            token0Amount,
            token1,
            token1Amount,
            router,
            returnResidual
        );
    }

    /// @notice Returns the optimal intra-pool swap quantity such that
    /// that the proportion of both tokens held subsequent to the swap is
    /// equal to the proportion of the assets in the pool. Assumes typical
    /// Uniswap V2 fee.
    /// @param reserves The reserves of the sellToken
    /// @param amount The total quantity of tokens held
    /// @return The quantity of the sell token to swap
    function _getSwapAmount(uint256 reserves, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserves * ((amount * 3988000) + (reserves * 3988009))
            ) - (reserves * 1997)) / 1994;
    }

    /// @notice Used for intra-pool swaps of ERC20 assets
    /// @param sellToken The token address to swap from
    /// @param sellAmount The quantity of tokens to sell
    /// @param buyToken The token address to swap to
    /// @param router The Uniswap V2-like router to use for the swap
    /// @return tokenBought The quantity of tokens bought
    function _intraSwap(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        IUniswapV2Router02 router
    ) internal returns (uint256) {
        if (sellToken == buyToken) {
            return sellAmount;
        }

        _approve(sellToken, address(router), sellAmount);

        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = buyToken;

        uint256 beforeSwap = _getBalance(address(this), buyToken);

        router.swapExactTokensForTokens(
            sellAmount,
            1,
            path,
            address(this),
            block.timestamp
        );

        return _getBalance(address(this), buyToken) - beforeSwap;
    }

    /// @notice Deposits both tokens into the pool
    /// @param token0Amount The quantity of token0 to add to the pool
    /// @param token1 The address of the 1st token in the pool
    /// @param token1Amount The quantity of token1 to add to the pool
    /// @param router The Uniswap V2-like router to use to add liquidity
    /// @param returnResidual Return residual, if any, that remains
    /// following the deposit. Note: Probably a waste of gas to set to true
    /// @return liquidity pool tokens acquired
    function _addLiquidity(
        address buyToken,
        address token0,
        uint256 token0Amount,
        address token1,
        uint256 token1Amount,
        IUniswapV2Router02 router,
        bool returnResidual
    ) internal returns (uint256) {
        _approve(token0, address(router), token0Amount);
        _approve(token1, address(router), token1Amount);

        uint256 beforeLiquidity = _getBalance(msg.sender, buyToken);

        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
            token0,
            token1,
            token0Amount,
            token1Amount,
            1,
            1,
            msg.sender,
            block.timestamp
        );

        if (returnResidual) {
            if (token0Amount - amountA > 0) {
                ERC20(token0).safeTransfer(msg.sender, token0Amount - amountA);
            }
            if (token1Amount - amountB > 0) {
                ERC20(token1).safeTransfer(msg.sender, token1Amount - amountB);
            }
        }
        return _getBalance(msg.sender, buyToken) - beforeLiquidity;
    }
}