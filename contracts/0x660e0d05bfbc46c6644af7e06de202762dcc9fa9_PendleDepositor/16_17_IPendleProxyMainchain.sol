// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IPendleProxy.sol";

interface IPendleProxyMainchain is IPendleProxy {
    function lockPendle(uint128 _expiry) external;

    // --- Events ---
    event DepositorUpdated(address _depositor);
    event EPendleRewardPoolUpdated(address _ePendleRewardPool);
    event FeeDistributorV2Updated(address _feeDistributorV2);
    event FeeCollectorUpdated(address _feeCollector);
    event PendleLocked(uint128 _additionalAmountToLock, uint128 _newExpiry);

    event FeesClaimed(
        address[] _pools,
        uint256 _totalAmountOut,
        uint256[] _amountsOut
    );
}