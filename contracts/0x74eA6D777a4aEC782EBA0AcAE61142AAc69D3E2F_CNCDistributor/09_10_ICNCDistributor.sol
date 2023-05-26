// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ICNCDistributor {
    event InflationSharesUpdated(uint256 gaugeInflationShare);

    event GaugeTopUp(uint256 amount);

    function topUpGauge() external;

    function donate(uint256 amount) external;

    function withdrawOtherToken(address token) external;

    function updateInflationShare(uint256 _gaugeInflationShare) external;

    function executeInflationRateUpdate() external;

    function shutdown() external;

    function isShutdown() external view returns (bool);

    function gaugeInflationShare() external view returns (uint256);

    function currentInflationRate() external view returns (uint256);

    function lastInflationRateDecay() external view returns (uint256);

    function setGaugeRewardDistributor(address newDistributor) external;
}