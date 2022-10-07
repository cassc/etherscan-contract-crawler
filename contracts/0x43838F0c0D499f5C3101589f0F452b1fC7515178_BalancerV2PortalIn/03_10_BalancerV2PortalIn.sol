/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Balancer V2 like pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV2.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IBalancerVault.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract BalancerV2PortalIn is PortalBaseV2 {
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

    /// @notice Add liquidity to Balancer V2 like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be one of the pool tokens)
    /// @param buyToken The Balancer V2 pool address (i.e. the LP token address)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolData Encoded contextual pool data for the join
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
        bytes calldata poolData
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        buyAmount = _deposit(intermediateToken, amount, buyToken, poolData);

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

    /// @notice Deposits the sellToken into the pool
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to deposit
    /// @param buyToken The Balancer V2 pool token address
    /// @param poolData Encoded pool data including the following:
    /// poolId The balancer pool ID
    /// assets An array of all tokens in the pool
    /// The index of the sellToken in the pool
    /// The address of the Balancer V2 like vault
    /// @return liquidity The quantity of LP tokens acquired
    function _deposit(
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

        uint256[] memory maxAmountsIn = new uint256[](assets.length);
        maxAmountsIn[index] = sellAmount;

        bytes memory userData = abi.encode(1, maxAmountsIn, 0);

        uint256 balance = _getBalance(msg.sender, buyToken);

        uint256 valueToSend;
        if (sellToken == address(0)) {
            valueToSend = sellAmount;
        } else {
            _approve(sellToken, address(vault), sellAmount);
        }

        vault.joinPool{ value: valueToSend }(
            poolId,
            address(this),
            msg.sender,
            IBalancerVault.JoinPoolRequest({
                assets: assets,
                maxAmountsIn: maxAmountsIn,
                userData: userData,
                fromInternalBalance: false
            })
        );

        return _getBalance(msg.sender, buyToken) - balance;
    }
}