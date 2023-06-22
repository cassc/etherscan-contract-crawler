// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IMiningPool {
    event Allocated(uint256 amount);
    event Dispatched(address indexed user, uint256 numOfMiners);
    event Withdrawn(address indexed user, uint256 numOfMiners);
    event Mined(address indexed user, uint256 amount);

    function initialize(address _tokenEmitter, address _baseToken) external;

    function allocate(uint256 amount) external;

    function token() external view returns (address);

    function tokenEmitter() external view returns (address);

    function baseToken() external view returns (address);

    function miningEnds() external view returns (uint256);

    function miningRate() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function lastTimeMiningApplicable() external view returns (uint256);

    function tokenPerMiner() external view returns (uint256);

    function mined(address account) external view returns (uint256);

    function getMineableForPeriod() external view returns (uint256);

    function paidTokenPerMiner(address account) external view returns (uint256);

    function dispatchedMiners(address account) external view returns (uint256);

    function totalMiners() external view returns (uint256);
}