// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// LIBRARIES
import { CurveV1AdapterBase } from "./CurveV1_Base.sol";

// INTERFACES
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";

/// @title CurveV1AdapterDeposit adapter
/// @dev Implements logic for interacting with a Curve zap wrapper (to remove_liquidity_one_coin from older pools)
contract CurveV1AdapterDeposit is CurveV1AdapterBase {
    AdapterType public constant override _gearboxAdapterType =
        AdapterType.CURVE_V1_WRAPPER;

    /// @dev Sets allowance for the pool LP token before and after operation
    modifier withLPTokenApproval() {
        _approveToken(lp_token, type(uint256).max);
        _;
        _approveToken(lp_token, type(uint256).max);
    }

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _curveDeposit Address of the target Curve deposit contract
    /// @param _lp_token Address of the pool's LP token
    /// @param _nCoins Number of coins supported by the wrapper
    constructor(
        address _creditManager,
        address _curveDeposit,
        address _lp_token,
        uint256 _nCoins
    )
        CurveV1AdapterBase(
            _creditManager,
            _curveDeposit,
            _lp_token,
            address(0),
            _nCoins
        )
    {}

    /// @dev Sends an order to remove liquidity from the pool in a single asset,
    /// using a deposit zap contract
    /// @param i Index of the token to withdraw from the pool
    /// - Unlike other adapters, approves the LP token to the target
    /// @notice See more implementation details in CurveV1AdapterBase
    function remove_liquidity_one_coin(
        uint256, // _token_amount,
        int128 i,
        uint256 // min_amount
    ) external virtual override nonReentrant withLPTokenApproval {
        address tokenOut = _get_token(i);
        _remove_liquidity_one_coin(tokenOut);
    }

    /// @dev Sends an order to remove all liquidity from the pool in a single asset
    /// using a deposit zap contract
    /// @param i Index of the token to withdraw from the pool
    /// @param minRateRAY The minimum exchange rate of the LP token to the received asset
    /// - Unlike other adapters, approves the LP token to the target
    /// @notice See more implementation details in CurveV1AdapterBase
    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external
        virtual
        override
        nonReentrant
        withLPTokenApproval
    {
        address tokenOut = _get_token(i); // F:[ACV1-4]
        _remove_all_liquidity_one_coin(i, tokenOut, minRateRAY); // F:[ACV1-10]
    }
}