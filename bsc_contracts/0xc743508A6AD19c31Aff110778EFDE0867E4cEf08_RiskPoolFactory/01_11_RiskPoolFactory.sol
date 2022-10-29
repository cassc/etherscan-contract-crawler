// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "../RiskPool.sol";
import "../interfaces/IRiskPoolFactory.sol";

contract RiskPoolFactory is IRiskPoolFactory {
    constructor() {}

    function newRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _cohort,
        address _currency
    ) external override returns (address) {
        RiskPool _riskPool = new RiskPool(_name, _symbol, _cohort, _currency);
        address _riskPoolAddr = address(_riskPool);

        return _riskPoolAddr;
    }
}