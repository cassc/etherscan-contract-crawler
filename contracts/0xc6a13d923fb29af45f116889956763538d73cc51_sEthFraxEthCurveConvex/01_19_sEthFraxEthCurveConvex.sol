//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../../../../utils/Constants.sol';
import './FrxEthCurveConvexStratBase.sol';

contract sEthFraxEthCurveConvex is FrxEthCurveConvexStratBase {
    constructor(Config memory config)
        FrxEthCurveConvexStratBase(
            config,
            Constants.CRV_FRAX_sETH_ADDRESS,
            Constants.CRV_FRAX_sETH_LP_ADDRESS,
            Constants.CVX_FRAX_sETH_REWARDS_ADDRESS,
            Constants.CVX_FRAX_sETH_PID
        )
    {}
}