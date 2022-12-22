/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract mints and locks StakeDAO sdTokens using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV2.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IDepositor.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract StakeDAOPortalIn is PortalBaseV2 {
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

    /// @notice Mints and locks StakeDAO sdTokens with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The sdToken or vault underlying token
    /// @param buyToken The address of the Stake DAO sdToken depositor or vault contract
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param isLP True if buyToken is a liquidity pool, false if it is a basic token
    /// @return buyAmount The quantity of gauge tokens of buyToken acquired (note: the tokens are locked in the gauge!)
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bool isLP
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount);

        amount = _execute(sellToken, amount, intermediateToken, target, data);

        _approve(intermediateToken, buyToken, amount);

        address gauge;

        if (isLP) {
            gauge = IDepositor(buyToken).liquidityGauge();
            buyAmount = _getBalance(msg.sender, gauge);
            IDepositor(buyToken).deposit(
                msg.sender,
                amount,
                true //earn
            );
        } else {
            gauge = IDepositor(buyToken).gauge();
            buyAmount = _getBalance(msg.sender, gauge);
            IDepositor(buyToken).deposit(
                amount,
                true, //lock
                true, //stake
                msg.sender
            );
        }

        buyAmount = _getBalance(msg.sender, gauge) - buyAmount;

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            gauge,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}