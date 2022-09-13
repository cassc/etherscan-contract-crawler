//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IProntera {
    struct UserInfo {
        uint256 jellopy;
        uint256 rewardDebt;
        uint256 storedJellopy;
    }

    function userInfo(address npc, address user) external view returns (UserInfo memory);

    struct PoolInfo {
        address want;
        address izlude;
        uint256 accKSWPerJellopy;
        uint64 allocPoint;
        uint64 lastRewardTime;
    }

    function poolInfo(address izlude) external view returns (PoolInfo memory);

    function pendingKSW(address izlude, address _user) external view returns (uint256);

    function deposit(address izlude, uint256 amount) external;

    function depositFor(
        address user,
        address izlude,
        uint256 amount
    ) external;

    function withdraw(address izlude, uint256 jellopyAmount) external;

    function emergencyWithdraw(address izlude) external;

    function storeWithdraw(
        address _user,
        address izlude,
        uint256 jellopyAmount
    ) external;

    function storeKeepJellopy(
        address _user,
        address izlude,
        uint256 amount
    ) external;

    function storeReturnJellopy(
        address _user,
        address izlude,
        uint256 amount
    ) external;

    function juno() external returns (address);
}