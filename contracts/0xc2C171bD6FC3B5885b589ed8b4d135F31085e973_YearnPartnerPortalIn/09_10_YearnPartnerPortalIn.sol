/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Yearn Vaults using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "./interface/IYearnPartnerTracker.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract YearnPartnerPortalIn is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IYearnPartnerTracker immutable YearnPartnerTracker;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The msg.sender
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
        uint256 fee,
        IYearnPartnerTracker yearnPartnerTracker
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        YearnPartnerTracker = yearnPartnerTracker;
    }

    /// @notice Add liquidity to Yearn like vaults with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be the vault underlying token)
    /// @param buyToken The vault token address (i.e. the vault token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param yearnAffiliate The Yearn affiliate address
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
        address yearnAffiliate
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        uint256 balance = _getBalance(address(this), buyToken);

        _approve(intermediateToken, address(YearnPartnerTracker), amount);
        YearnPartnerTracker.deposit(buyToken, yearnAffiliate, amount);

        buyAmount = _getBalance(address(this), buyToken) - balance;

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

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
}