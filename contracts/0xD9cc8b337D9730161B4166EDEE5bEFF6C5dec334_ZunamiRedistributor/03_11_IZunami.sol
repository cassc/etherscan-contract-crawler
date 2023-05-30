// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IZunamiStrategy.sol';

interface IZunami is IERC20 {
    struct PoolInfo {
        IZunamiStrategy strategy;
        uint256 startTime;
        uint256 lpShares;
    }

    function tokens(uint256 index) external view returns (address);

    function delegateWithdrawal(uint256 lpShares, uint256[3] memory tokenAmounts) external;

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function poolCount() external view returns (uint256);
}