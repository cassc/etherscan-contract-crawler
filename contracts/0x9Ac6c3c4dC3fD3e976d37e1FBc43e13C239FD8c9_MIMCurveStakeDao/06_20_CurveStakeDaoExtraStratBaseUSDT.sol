//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CurveStakeDaoExtraStratBase.sol";

abstract contract CurveStakeDaoExtraStratBaseUSDT is CurveStakeDaoExtraStratBase {
    constructor(
        Config memory config,
        address vaultAddr,
        address poolLpAddr,
        address tokenAddr,
        address extraTokenAddr
    ) CurveStakeDaoExtraStratBase(
        config,
        vaultAddr,
        poolLpAddr,
        tokenAddr,
        extraTokenAddr,
        [Constants.WETH_ADDRESS, Constants.USDT_ADDRESS]
    ) { }
}