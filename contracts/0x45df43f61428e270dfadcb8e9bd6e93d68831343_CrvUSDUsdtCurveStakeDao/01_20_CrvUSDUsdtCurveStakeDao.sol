//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './UsdtCurveStakeDaoStrat.sol';

contract CrvUSDUsdtCurveStakeDao is UsdtCurveStakeDaoStrat {
    constructor(Config memory config)
    UsdtCurveStakeDaoStrat(
            config,
            Constants.SDT_CRVUSD_USDT_VAULT_ADDRESS,
            Constants.CRV_CRVUSD_USDT_LP_ADDRESS,
            Constants.CRVUSD_ADDRESS,
            Constants.CRV_CRVUSD_USDT_ADDRESS,
            address(0)
        )
    {}
}