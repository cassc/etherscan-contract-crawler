//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./IStrategy.sol";

interface IZunamiVault is IERC20 {
    struct PoolInfo {
        IStrategy strategy;
        uint256 startTime;
        uint256 lpShares;
    }

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function defaultDepositPid() external view returns (uint256);

    function defaultWithdrawPid() external view returns (uint256);

    function withdraw(
        uint256 lpShares,
        uint256[3] memory tokenAmounts,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external;

    function deposit(uint256[3] memory amounts) external returns (uint256);

    function calcWithdrawOneCoin(uint256 lpShares, uint128 tokenIndex)
    external
    view
    returns (uint256 tokenAmount);
}