// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Crv4PoolStrategy.sol";

//solhint-disable no-empty-blocks
contract Crv4PoolStrategySUSDPool is Crv4PoolStrategy {
    // SUSD LP Token
    address internal constant CRV_LP = 0xC25a3A3b969415c80451098fa907EC722572917F;
    // SUSD Pool
    address internal constant CRV_POOL = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    // SUSD Deposit Contract
    address internal constant CRV_DEPOSIT = 0xFCBa3E75865d2d561BE8D220616520c171F12851;
    // SUSD Gauge
    address internal constant GAUGE = 0xA90996896660DEcC6E997655E065b23788857849;

    constructor(
        address _pool,
        address _swapManager,
        uint256 _collateralIdx,
        string memory _name
    ) Crv4PoolStrategy(_pool, _swapManager, CRV_DEPOSIT, CRV_POOL, CRV_LP, GAUGE, _collateralIdx, _name) {}
}