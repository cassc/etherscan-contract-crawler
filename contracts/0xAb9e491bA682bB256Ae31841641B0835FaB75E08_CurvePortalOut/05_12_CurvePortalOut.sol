/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Curve pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV2.sol";
import "./interface/ICurveAddressProvider.sol";
import "./interface/ICurvePool.sol";
import "./interface/ICurveRegistry.sol";

/// Thrown when insufficient liquidity is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract CurvePortalOut is PortalBaseV2 {
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

    /// @notice Removes liquidity from Curve pools into network tokens/ERC20 tokens
    /// @param sellToken The curve pool token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolData Encoded pool data including the following for the pool and metapool sequentially (if applicable):
    /// pool The address of the swap/deposit contract (address(0) for metapool set if not metapool)
    /// intermediateToken The address of the token at the index
    /// The index of the token being removed from the pool (i.e the index of intermediateToken)
    /// isInt128 A boolean value specifying whether the index is int128 or uint256
    /// removeUnderlying A boolean value specifying whether to withdraw the unwrapped version of the token
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes calldata poolData
    ) external payable pausable returns (uint256 buyAmount) {
        sellAmount = _transferFromCaller(sellToken, sellAmount);

        address intermediateToken;
        (sellAmount, intermediateToken) = _remove(
            sellToken,
            sellAmount,
            poolData
        );

        buyAmount = _execute(
            intermediateToken,
            sellAmount,
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

    /// @notice Handles removal of tokens and parsing of pooldata for pools and metapools
    /// @param sellToken The curve pool token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param poolData Encoded pool data including the following for the pool and metapool sequentially (if applicable):
    /// pool The address of the swap/deposit contract (address(0) for metapool set if not metapool)
    /// intermediateToken The address of the token at the index
    /// The index of the token being removed from the pool (i.e the index of intermediateToken)
    /// isInt128 A boolean value specifying whether the index is int128 or uint256
    /// removeUnderlying A boolean value specifying whether to withdraw the unwrapped version of the token
    /// @return buyAmount The quantity buyToken acquired
    /// @return intermediateToken The address of the intermediate token to swap to buyToken
    function _remove(
        address sellToken,
        uint256 sellAmount,
        bytes calldata poolData
    ) internal returns (uint256 buyAmount, address intermediateToken) {
        address pool;
        uint256 coinIndex;
        bool isInt128;
        bool removeUnderlying;

        (
            pool,
            intermediateToken,
            coinIndex,
            isInt128,
            removeUnderlying
        ) = _parsePoolData(poolData, false);

        buyAmount = _exitCurve(
            sellToken,
            sellAmount,
            pool,
            intermediateToken,
            coinIndex,
            isInt128,
            removeUnderlying
        );

        if (
            keccak256(abi.encodePacked(poolData[160:180])) !=
            keccak256(abi.encodePacked(address(0)))
        ) {
            address poolToken = intermediateToken;
            (
                pool,
                intermediateToken,
                coinIndex,
                isInt128,
                removeUnderlying
            ) = _parsePoolData(poolData, true);

            buyAmount = _exitCurve(
                poolToken,
                buyAmount,
                pool,
                intermediateToken,
                coinIndex,
                isInt128,
                removeUnderlying
            );
        }
    }

    /// @notice Removes liquidity from the pool
    /// @param sellToken The curve pool token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param pool The address of the swap/deposit contract (address(0) for metapool set if not metapool)
    /// @param coinIndex The index of the token being removed from the pool (i.e the index of intermediateToken)
    /// @param isInt128 A boolean value specifying whether the index is int128 or uint256
    /// @param removeUnderlying A boolean value specifying whether to withdraw the unwrapped version of the token
    /// @return buyAmount The quantity buyToken acquired
    function _exitCurve(
        address sellToken,
        uint256 sellAmount,
        address pool,
        address buyToken,
        uint256 coinIndex,
        bool isInt128,
        bool removeUnderlying
    ) internal returns (uint256) {
        _approve(sellToken, pool, sellAmount);

        uint256 balance = _getBalance(address(this), buyToken);

        ICurvePool _pool = ICurvePool(pool);

        if (isInt128) {
            if (removeUnderlying) {
                _pool.remove_liquidity_one_coin(
                    sellAmount,
                    int128(uint128(coinIndex)),
                    0,
                    true
                );
            } else {
                _pool.remove_liquidity_one_coin(
                    sellAmount,
                    int128(uint128(coinIndex)),
                    0
                );
            }
        } else {
            if (removeUnderlying) {
                _pool.remove_liquidity_one_coin(sellAmount, coinIndex, 0, true);
            } else {
                _pool.remove_liquidity_one_coin(sellAmount, coinIndex, 0);
            }
        }

        return _getBalance(address(this), buyToken) - balance;
    }

    function _parsePoolData(bytes calldata poolData, bool isMetapool)
        internal
        pure
        returns (
            address pool,
            address intermediateToken,
            uint256 coinIndex,
            bool isInt128,
            bool removeUnderlying
        )
    {
        if (isMetapool) {
            (
                ,
                ,
                ,
                ,
                ,
                pool,
                intermediateToken,
                coinIndex,
                isInt128,
                removeUnderlying
            ) = abi.decode(
                poolData,
                (
                    address,
                    address,
                    uint256,
                    bool,
                    bool,
                    address,
                    address,
                    uint256,
                    bool,
                    bool
                )
            );
        } else {
            (
                pool,
                intermediateToken,
                coinIndex,
                isInt128,
                removeUnderlying,
                ,
                ,
                ,
                ,

            ) = abi.decode(
                poolData,
                (
                    address,
                    address,
                    uint256,
                    bool,
                    bool,
                    address,
                    address,
                    uint256,
                    bool,
                    bool
                )
            );
        }
    }
}