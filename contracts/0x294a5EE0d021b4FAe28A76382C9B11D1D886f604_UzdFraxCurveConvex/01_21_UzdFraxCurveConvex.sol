//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../../../utils/Constants.sol';
import './FraxCurveConvexApsStratBase.sol';

contract UzdFraxCurveConvex is FraxCurveConvexApsStratBase {
    constructor(Config memory config)
        FraxCurveConvexApsStratBase(
            config,
            Constants.ZUNAMI_POOL_ADDRESS,
            Constants.ZUNAMI_STABLE_ADDRESS,
            Constants.FRAX_USDC_ADDRESS,
            Constants.FRAX_USDC_LP_ADDRESS,
            Constants.CRV_FRAX_UZD_ADDRESS,
            Constants.CRV_FRAX_UZD_LP_ADDRESS,
            Constants.CVX_FRAX_UZD_REWARDS_ADDRESS,
            Constants.CVX_FRAX_UZD_PID,
            Constants.UZD_ADDRESS,
            address(0),
            address(0)
        )
    {}
}