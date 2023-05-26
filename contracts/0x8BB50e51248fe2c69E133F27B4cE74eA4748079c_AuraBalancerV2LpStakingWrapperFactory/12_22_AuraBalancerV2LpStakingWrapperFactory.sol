// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../convex-curve-lp/ConvexCurveLpStakingWrapperFactory.sol";

/// @title AuraBalancerV2LpStakingWrapperFactory Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract factory for Aura BalancerV2 staking wrapper instances
contract AuraBalancerV2LpStakingWrapperFactory is ConvexCurveLpStakingWrapperFactory {
    constructor(
        address _dispatcher,
        address _auraBooster,
        address _balToken,
        address _auraToken
    )
        public
        ConvexCurveLpStakingWrapperFactory(_dispatcher, _auraBooster, _balToken, _auraToken)
    {}
}