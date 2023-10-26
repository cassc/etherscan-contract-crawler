//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

interface IDividendPool {
    function distribute(address token, uint256 amount) external;

    function veVISION() external view returns (address);

    function veLocker() external view returns (address);

    function genesis() external view returns (uint256);

    function getEpoch(uint256 timestamp) external view returns (uint256);

    function getCurrentEpoch() external view returns (uint256);

    function distributedTokens() external view returns (address[] memory);

    function totalDistributed(address token) external view returns (uint256);

    function distributionBalance(address token) external view returns (uint256);

    function distributionOfWeek(address token, uint256 epochNum)
        external
        view
        returns (uint256);

    function claimStartWeek(address token, uint256 veLockId)
        external
        view
        returns (uint256);

    function claimable(address token) external view returns (uint256);

    function featuredRewards() external view returns (address[] memory);
}