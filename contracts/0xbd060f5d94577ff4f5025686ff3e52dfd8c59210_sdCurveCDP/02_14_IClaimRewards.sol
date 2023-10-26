// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IClaimRewards {
    function claimRewards(address[] calldata _gauges) external;

    struct LockStatus {
        bool[] locked;
        bool[] staked;
        bool lockSDT;
    }

    function claimAndLock(
        address[] memory _gauges,
        LockStatus memory _lockStatus
    ) external;

    function rescueERC20(
        address _token,
        uint256 _amount,
        address _recipient
    ) external;

    function enableGauge(address _gauge) external;

    function disableGauge(address _gauge) external;

    function addDepositor(address _token, address _depositor) external;

    function setGovernance(address _governance) external;
}