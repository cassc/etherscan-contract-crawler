// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRewarderV2.sol";

interface IMasterApeV2 {
    function updateEmissionRate(uint256 _bananaPerSecond, bool _withUpdate) external; // onlyOwner

    function updateHardCap(uint256 _hardCap) external; // onlyOwner

    function setFeeAddress(address _feeAddress) external; // onlyOwner

    function add(
        uint256 _allocPoint,
        IERC20 _stakeToken,
        bool _withUpdate,
        uint16 _depositFeeBP,
        IRewarderV2 _rewarder
    ) external; // onlyOwner

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate,
        uint16 _depositFeeBP,
        IRewarderV2 _rewarder
    ) external; // onlyOwner

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external; // validatePool(_pid);

    function depositTo(uint256 _pid, uint256 _amount, address _to) external; // validatePool(_pid);

    function deposit(uint256 _pid, uint256 _amount) external; // validatePool(_pid);

    function withdraw(uint256 _pid, uint256 _amount) external; // validatePool(_pid);

    function withdrawTo(uint256 _pid, uint256 _amount, address _to) external; // validatePool(_pid);

    function emergencyWithdraw(uint256 _pid) external;

    function setPendingMasterApeV1Owner(address _pendingMasterApeV1Owner) external;

    function acceptMasterApeV1Ownership() external;

    function bananaPerSecond() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingBanana(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);

    function getPoolInfo(
        uint256 _pid
    )
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            IRewarderV2 rewarder,
            uint256 lastRewardBlock,
            uint256 accBananaPerShare,
            uint256 totalStaked,
            uint16 depositFeeBP
        );
}