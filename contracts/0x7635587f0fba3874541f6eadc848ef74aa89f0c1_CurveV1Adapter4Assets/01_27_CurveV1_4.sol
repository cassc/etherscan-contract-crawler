// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IAdapter, AdapterType} from "../../interfaces/IAdapter.sol";

import {N_COINS} from "../../integrations/curve/ICurvePool_4.sol";
import {ICurveV1_4AssetsAdapter} from "../../interfaces/curve/ICurveV1_4AssetsAdapter.sol";
import {CurveV1AdapterBase} from "./CurveV1_Base.sol";

/// @title Curve V1 4 assets adapter interface
/// @notice Implements logic allowing to interact with Curve pools with 4 assets
contract CurveV1Adapter4Assets is CurveV1AdapterBase, ICurveV1_4AssetsAdapter {
    AdapterType public constant override(CurveV1AdapterBase, IAdapter) _gearboxAdapterType =
        AdapterType.CURVE_V1_4ASSETS;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _curvePool Target Curve pool address
    /// @param _lp_token Pool LP token address
    /// @param _metapoolBase Base pool address (for metapools only) or zero address
    constructor(address _creditManager, address _curvePool, address _lp_token, address _metapoolBase)
        CurveV1AdapterBase(_creditManager, _curvePool, _lp_token, _metapoolBase, N_COINS)
    {}

    /// @inheritdoc ICurveV1_4AssetsAdapter
    function add_liquidity(uint256[N_COINS] calldata amounts, uint256) external creditFacadeOnly {
        _add_liquidity(amounts[0] > 1, amounts[1] > 1, amounts[2] > 1, amounts[3] > 1); // F: [ACV1_4-4]
    }

    /// @inheritdoc ICurveV1_4AssetsAdapter
    function remove_liquidity(uint256, uint256[N_COINS] calldata) external virtual creditFacadeOnly {
        _remove_liquidity(); // F: [ACV1_4-5]
    }

    /// @inheritdoc ICurveV1_4AssetsAdapter
    function remove_liquidity_imbalance(uint256[N_COINS] calldata amounts, uint256)
        external
        virtual
        override
        creditFacadeOnly
    {
        _remove_liquidity_imbalance(amounts[0] > 1, amounts[1] > 1, amounts[2] > 1, amounts[3] > 1); // F: [ACV1_4-6]
    }
}