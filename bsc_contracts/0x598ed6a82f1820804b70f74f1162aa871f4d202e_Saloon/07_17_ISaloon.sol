// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ISaloon {
    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint8 tokenDecimals;
        uint16 apy;
        address projectWallet;
        string projectName;
        uint256 projectDeposit;
        uint256 poolCap;
        uint256 totalStaked;
        uint256 requiredPremiumBalancePerPeriod;
        uint256 premiumBalance;
        uint256 premiumAvailable;
        TimelockInfo poolTimelock;
        address[] stakerList;
        bool isActive;
        uint256 freezeTime;
    }

    struct TimelockInfo {
        uint256 timelock;
        uint256 timeLimit;
        uint256 withdrawalScheduledAmount;
        bool withdrawalExecuted;
    }
}