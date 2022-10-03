//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../utils/Constants.sol';
import "./CurveStakeDaoStrat2.sol";

contract MIMCurveStakeDao is CurveStakeDaoStrat2 {
    constructor(Config memory config)
    CurveStakeDaoStrat2(
        config,
        Constants.SDT_MIM_VAULT_ADDRESS,
        Constants.CRV_MIM_LP_ADDRESS,
        Constants.MIM_ADDRESS,
        Constants.CRV_3POOL_ADDRESS,
        Constants.CRV_3POOL_LP_ADDRESS,
        Constants.CRV_MIM_ADDRESS,
        Constants.SDT_MIM_SPELL_ADDRESS
    )
    {}
}