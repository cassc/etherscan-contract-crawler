/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Balancer V2 like pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV2.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IBalancerVault.sol";

/// Thrown when insufficient buyAmount is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract BalancerV2PortalOut is PortalBaseV2 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

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

    /// @notice Remove liquidity from Balancer V2 like pools into network tokens/ERC20 tokens
    /// @param sellToken The Balancer V2 pool address (i.e. the LP token address)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap from (must be one of the pool tokens)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolData Encoded contextual pool data for the exit
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes calldata poolData
    ) external payable pausable returns (uint256 buyAmount) {
        sellAmount = _transferFromCaller(sellToken, sellAmount);

        uint256 intermediateAmount = _withdraw(
            sellToken,
            sellAmount,
            intermediateToken,
            poolData
        );

        buyAmount = _execute(
            intermediateToken,
            intermediateAmount,
            buyToken,
            target,
            data
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

    /// @notice Removes the intermediate token from the pool
    /// @param sellToken The pool address
    /// @param sellAmount The quantity of LP tokens to remove from the pool
    /// @param buyToken The ERC20 token being removed (i.e. the intermediate token)
    /// @param poolData Encoded pool data including the following:
    /// poolId The balancer pool ID
    /// assets An array of all tokens in the pool
    /// The index of the intermediate in the pool
    /// The address of the Balancer V2 like vault
    /// @return liquidity The quantity of LP tokens acquired
    function _withdraw(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        bytes calldata poolData
    ) internal returns (uint256) {
        (
            bytes32 poolId,
            address[] memory assets,
            uint256 index,
            IBalancerVault vault
        ) = abi.decode(poolData, (bytes32, address[], uint256, IBalancerVault));

        uint256[] memory minAmountsOut = new uint256[](assets.length);

        bytes memory userData = abi.encode(0, sellAmount, index);

        uint256 balance = _getBalance(address(this), buyToken);

        _approve(sellToken, address(vault), sellAmount);

        vault.exitPool(
            poolId,
            address(this),
            payable(address(this)),
            IBalancerVault.ExitPoolRequest({
                assets: assets,
                minAmountsOut: minAmountsOut,
                userData: userData,
                toInternalBalance: false
            })
        );

        return _getBalance(address(this), buyToken) - balance;
    }
}