// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
// pragma experimental ABIEncoderV2;
import { IERC20 } from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IMasterChefWithdraw {
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

    function userInfo(uint256 pid, address user) external view returns (UserInfo memory);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

interface IMasterChef is IMasterChefWithdraw {
    function deposit(uint256 _pid, uint256 _amount) external;
}

interface IMasterChefWithRef is IMasterChefWithdraw {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _ref
    ) external;
}