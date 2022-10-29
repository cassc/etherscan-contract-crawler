// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "../Rewarder.sol";
import "../interfaces/IRewarderFactory.sol";

contract RewarderFactory is IRewarderFactory {
    constructor() {}

    function newRewarder(
        address _operator,
        address _currency,
        address _pool
    ) external override returns (address) {
        Rewarder _rewarder = new Rewarder(_operator, _currency, _pool);
        address _rewarderAddr = address(_rewarder);

        return _rewarderAddr;
    }
}