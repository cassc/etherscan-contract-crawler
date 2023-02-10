// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { N_COINS, ICurvePool2Assets } from "../../integrations/curve/ICurvePool_2.sol";
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { CurveV1Adapter2Assets } from "./CurveV1_2.sol";

/// @title CurveV1AdapterStETH adapter
/// @dev Inherits from CurveV1Adapter2Assets but designed to work with CurveV1StETH Gateway.
/// This adapter needs to approve the LP token to the gateway, as it needs to do a transferFrom
contract CurveV1AdapterStETH is CurveV1Adapter2Assets {
    function _gearboxAdapterType()
        external
        pure
        override
        returns (AdapterType)
    {
        return AdapterType.CURVE_V1_STECRV_POOL;
    }

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _curveStETHPoolGateway Address of the steCRV pool gateway
    /// @param _lp_token Address of the steCRV LP token
    constructor(
        address _creditManager,
        address _curveStETHPoolGateway,
        address _lp_token
    )
        CurveV1Adapter2Assets(
            _creditManager,
            _curveStETHPoolGateway,
            _lp_token,
            address(0)
        )
    {}

    /// @dev Sets allowance for the pool LP token before and after operation
    modifier withLPTokenApproval() {
        _approveToken(lp_token, type(uint256).max);
        _;
        _approveToken(lp_token, type(uint256).max);
    }

    /// @dev Sends an order to remove liquidity from a Curve pool
    /// - Unlike other adapters, approves the LP token to the target
    /// @notice See more implementation details in CurveV1Adapter2Assets
    function remove_liquidity(uint256, uint256[N_COINS] calldata)
        public
        override
        withLPTokenApproval // F:[ACV1S-2]
        nonReentrant
    {
        _remove_liquidity(); // F:[ACV1S-2]
    }

    /// @dev Sends an order to remove liquidity from the pool in a single asset
    /// @param i Index of the token to withdraw from the pool
    /// - Unlike other adapters, approves the LP token to the target
    /// @notice See more implementation details in CurveV1Adapter2Assets
    function remove_liquidity_one_coin(
        uint256, // _token_amount,
        int128 i,
        uint256 // min_amount
    )
        external
        override
        withLPTokenApproval // F:[ACV1S-4]
        nonReentrant
    {
        address tokenOut = _get_token(i); // F:[ACV1S-4]
        _remove_liquidity_one_coin(tokenOut); // F:[ACV1S-4]
    }

    /// @dev Sends an order to remove all liquidity from the pool in a single asset
    /// @param i Index of the token to withdraw from the pool
    /// @param minRateRAY The minimum exchange rate of the LP token to the received asset
    /// - Unlike other adapters, approves the LP token to the target
    /// @notice See more implementation details in CurveV1Adapter2Assets
    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external
        override
        withLPTokenApproval // F:[ACV1S-5]
        nonReentrant
    {
        address tokenOut = _get_token(i); // F:[ACV1S-5]
        _remove_all_liquidity_one_coin(i, tokenOut, minRateRAY); // F:[ACV1S-5]
    }

    /// @dev Sends an order to remove liquidity from a Curve pool in exact token amounts
    /// @param amounts Amounts of coins to withdraw
    /// - Unlike other adapters, approves the LP token to the target
    /// @notice See more implementation details in CurveV1Adapter2Assets
    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata amounts,
        uint256
    )
        external
        override
        withLPTokenApproval // F:[ACV1S-6]
        nonReentrant
    {
        _remove_liquidity_imbalance(
            amounts[0] > 1,
            amounts[1] > 1,
            false,
            false
        ); // F:[ACV1S-6]
    }
}