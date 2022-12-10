/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Pool Together pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV2.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IPrizePool.sol";

/// Thrown when insufficient buyAmount is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract PoolTogetherPortalOut is PortalBaseV2 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IPrizePool public immutable PRIZE_POOL;

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

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IPrizePool _prizePool
    )
        PortalBaseV2(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        PRIZE_POOL = _prizePool;
    }

    /// @notice Remove liquidity from Pool Together pools into network tokens/ERC20 tokens
    /// @param sellToken The Pool Together Ticket address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap to (i.e. the underlying pool token)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the swap
    /// @param data  The encoded call for the swap
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);

        uint256 intermediateAmount = PRIZE_POOL.withdrawFrom(
            address(this),
            amount
        );

        buyAmount = _execute(
            intermediateToken,
            intermediateAmount,
            buyToken,
            target,
            data
        );

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyAmount = _getFeeAmount(buyAmount);

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
}