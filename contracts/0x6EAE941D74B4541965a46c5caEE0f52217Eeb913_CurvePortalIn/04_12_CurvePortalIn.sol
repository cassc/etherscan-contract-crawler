/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Curve pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "./interface/ICurveAddressProvider.sol";
import "./interface/ICurvePool.sol";
import "./interface/ICurveRegistry.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract CurvePortalIn is PortalBaseV1_1 {
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
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Add liquidity to Curve pools with network tokens/ERC20 tokens
    /// @dev This contract can call itself in cases where the pool is a metapool.
    /// In these cases, transfers, events and fees are omitted.
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be one of the pool tokens)
    /// @param buyToken The curve pool token address
    /// NOTE This may be different from the swap/deposit address!
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolData Encoded pool data including the following:
    /// pool The address of the swap/deposit contract
    /// numCoins The number of coins in the pool
    /// The index of the intermediateToken in the pool
    /// depositUnderlying A boolean value specifying whether to deposit the unwrapped version of intermediateToken
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
        uint256 amount = sellAmount;
        if (msg.sender != address(this)) {
            amount = _transferFromCaller(sellToken, sellAmount);
            amount = _getFeeAmount(amount, fee);
        }
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        buyAmount = _deposit(intermediateToken, amount, buyToken, poolData);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        if (msg.sender != address(this)) {
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

    /// @notice Deposits the sellToken into the pool using the correct interface based on the
    /// number of coins in the pool
    /// @param sellToken The token address to swap from
    /// @param sellAmount The quantity of tokens to sell
    /// @param buyToken The curve pool token address
    /// @param poolData Encoded pool data including the following:
    /// pool The address of the swap/deposit contract
    /// numCoins The number of coins in the pool
    /// The index of the intermediateToken in the pool
    /// depositUnderlying A boolean value specifying whether to deposit the unwrapped version of intermediateToken
    /// @return liquidity The quantity of LP tokens acquired
    function _deposit(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        bytes calldata poolData
    ) internal returns (uint256) {
        (
            address pool,
            uint256 numCoins,
            uint256 coinIndex,
            bool depositUnderlying
        ) = abi.decode(poolData, (address, uint256, uint256, bool));

        uint256 valueToSend;
        if (sellToken == address(0)) {
            valueToSend = sellAmount;
        } else {
            _approve(sellToken, pool, sellAmount);
        }

        uint256 balance = _getBalance(address(this), buyToken);

        ICurvePool _pool = ICurvePool(pool);

        if (numCoins == 2) {
            uint256[2] memory _amounts;
            _amounts[coinIndex] = sellAmount;
            depositUnderlying
                ? _pool.add_liquidity{ value: valueToSend }(_amounts, 0, true)
                : _pool.add_liquidity{ value: valueToSend }(_amounts, 0);
        } else if (numCoins == 3) {
            uint256[3] memory _amounts;
            _amounts[coinIndex] = sellAmount;
            depositUnderlying
                ? _pool.add_liquidity{ value: valueToSend }(_amounts, 0, true)
                : _pool.add_liquidity{ value: valueToSend }(_amounts, 0);
        } else {
            uint256[4] memory _amounts;
            _amounts[coinIndex] = sellAmount;
            depositUnderlying
                ? _pool.add_liquidity{ value: valueToSend }(_amounts, 0, true)
                : _pool.add_liquidity{ value: valueToSend }(_amounts, 0);
        }
        return _getBalance(address(this), buyToken) - balance;
    }
}