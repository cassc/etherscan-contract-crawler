// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// LIBRARIES
import { CurveV1AdapterBase } from "./CurveV1_Base.sol";

// INTERFACES
import { N_COINS, ICurvePool2Assets } from "../../integrations/curve/ICurvePool_2.sol";
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";

/// @title CurveV1Adapter2Assets adapter
/// @dev Implements logic for interacting with a Curve pool with 2 assets
contract CurveV1Adapter2Assets is CurveV1AdapterBase, ICurvePool2Assets {
    function _gearboxAdapterType()
        external
        pure
        virtual
        override
        returns (AdapterType)
    {
        return AdapterType.CURVE_V1_2ASSETS;
    }

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _curvePool Address of the target contract Curve pool
    /// @param _lp_token Address of the pool's LP token
    /// @param _metapoolBase The base pool if this pool is a metapool, otherwise 0x0
    constructor(
        address _creditManager,
        address _curvePool,
        address _lp_token,
        address _metapoolBase
    )
        CurveV1AdapterBase(
            _creditManager,
            _curvePool,
            _lp_token,
            _metapoolBase,
            N_COINS
        )
    {}

    /// @dev Sends an order to add liquidity to a Curve pool
    /// @param amounts Amounts of tokens to add
    /// @notice 'min_mint_amount' is ignored since the calldata is routed directly to the target
    /// @notice Internal implementation details in CurveV1Base
    function add_liquidity(uint256[N_COINS] calldata amounts, uint256)
        external
        nonReentrant
    {
        _add_liquidity(amounts[0] > 1, amounts[1] > 1, false, false); // F:[ACV1_2-4, ACV1S-1]
    }

    /// @dev Sends an order to remove liquidity from a Curve pool
    /// @notice '_amount' and 'min_amounts' are ignored since the calldata is routed directly to the target
    /// @notice Internal implementation details in CurveV1Base
    function remove_liquidity(uint256, uint256[N_COINS] calldata)
        external
        virtual
        nonReentrant
    {
        _remove_liquidity(); // F:[ACV1_2-5]
    }

    /// @dev Sends an order to remove liquidity from a Curve pool in exact token amounts
    /// @param amounts Amounts of coins to withdraw
    /// @notice `max_burn_amount` is ignored since the calldata is routed directly to the target
    /// @notice Internal implementation details in CurveV1Base
    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata amounts,
        uint256
    ) external virtual override nonReentrant {
        _remove_liquidity_imbalance(
            amounts[0] > 1,
            amounts[1] > 1,
            false,
            false
        ); // F:[ACV1_2-6]
    }

    /// @dev Calculates the amount of LP token minted or burned based on added/removed coin amounts
    /// @param _amounts Amounts of coins to be added or removed from the pool
    /// @param _is_deposit Whether the tokens are added or removed
    function calc_token_amount(
        uint256[N_COINS] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256) {
        return
            ICurvePool2Assets(targetContract).calc_token_amount(
                _amounts,
                _is_deposit
            );
    }

    /// @dev Calculates the time-weighted average of initial and final balances
    /// @param _first_balances Initial cumulative balances
    /// @param _last_balances Final cumulative balances
    /// @param _time_elapsed Amount of time between initial and final balances
    function get_twap_balances(
        uint256[N_COINS] calldata _first_balances,
        uint256[N_COINS] calldata _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[N_COINS] memory) {
        return
            ICurvePool2Assets(targetContract).get_twap_balances(
                _first_balances,
                _last_balances,
                _time_elapsed
            );
    }

    /// @dev Returns the current balances of coins in the pool
    function get_balances() external view returns (uint256[N_COINS] memory) {
        return ICurvePool2Assets(targetContract).get_balances();
    }

    /// @dev Returns the balances of coins in the pool from the last block where it was updated
    function get_previous_balances()
        external
        view
        returns (uint256[N_COINS] memory)
    {
        return ICurvePool2Assets(targetContract).get_previous_balances();
    }

    /// @dev Returns cumulative balances for TWAP calculation
    function get_price_cumulative_last()
        external
        view
        returns (uint256[N_COINS] memory)
    {
        return ICurvePool2Assets(targetContract).get_price_cumulative_last();
    }
}