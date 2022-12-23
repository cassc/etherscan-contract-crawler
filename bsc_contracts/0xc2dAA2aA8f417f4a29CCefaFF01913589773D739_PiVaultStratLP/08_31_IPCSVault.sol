// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "./IERC20.sol";

interface IPCSVault
{
    
    /// @notice Info of each MCV2 user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of SUSHI entitled to the user.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256 boostMultiplier;
    }

    /// @notice Info of each MCV2 pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of SUSHI to distribute per block.
    struct PoolInfo {
        uint64 accCakePerShare;
        uint128 lastRewardBlock;
        uint64 allocPoint;
        uint256 totalBoostedShare;
        bool isRegular;
    }

    function userInfo(uint256 pid, address user) external view returns (UserInfo memory info);
    function poolInfo(uint256 pid) external view returns (PoolInfo memory pool);

    function poolLength() external view returns (uint256 pools);
    
    function lpToken(uint256 _pid) external view returns (address);

    function pendingCake(uint256 _pid, address _user)external;
    function massUpdatePools(uint256[] calldata pids)external;
    function updatePool(uint256 pid)external;
    function deposit(uint256 pid, uint256 amount)external;
    function withdraw(uint256 pid, uint256 amount)external;

}