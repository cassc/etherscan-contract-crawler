// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IMasterChef {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    function poolLength() external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);
    function userInfo(uint256 pid, address user) external view returns (IMasterChef.UserInfo memory);
    function totalAllocPoint() external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    // V2

    struct PoolInfoV2 {
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardTime; // Timestamp when SUSHI distribution occurred.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    function deposit(uint256 _pid, uint256 _amount, address _to) external;
    function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external;
    function updatePool(uint256 _pid) external returns (IMasterChef.PoolInfoV2 memory);
    function harvest(uint256 pid, address to) external;
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256 pending);
}