// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

interface IMasterChefV3 {
    function nonfungiblePositionManager() external view returns (address);

    function getLatestPeriodInfo(address _v3Pool) external view returns (uint256 cakePerSecond, uint256 endTime);

    function poolInfo(uint256 pid) external view returns (uint256, address, address, address, uint24, uint256, uint256);
}