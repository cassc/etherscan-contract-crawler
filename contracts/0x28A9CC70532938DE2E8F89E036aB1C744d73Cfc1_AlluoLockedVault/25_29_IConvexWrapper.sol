// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IConvexWrapper {
    struct EarnedData {
        address token;
        uint256 amount;
    }

    function convexPoolId() external view returns (uint256 _poolId);

    function balanceOf(address _account) external view returns (uint256);

    function totalBalanceOf(address _account) external view returns (uint256);

    function deposit(uint256 _amount, address _to) external;

    function stake(uint256 _amount, address _to) external;

    function withdraw(uint256 _amount) external;

    function withdrawAndUnwrap(uint256 _amount) external;

    function getReward(address _account) external;

    function getReward(address _account, address _forwardTo) external;

    function rewardLength() external view returns (uint256);

    function earned(
        address _account
    ) external view returns (EarnedData[] memory claimable);

    function earnedView(
        address _account
    ) external view returns (EarnedData[] memory claimable);

    function setVault(address _vault) external;

    function user_checkpoint(
        address[2] calldata _accounts
    ) external returns (bool);

    function createVault(uint256 _pid) external returns (address);

    function stakeLockedCurveLp(
        uint256 _liquidity,
        uint256 _secs
    ) external returns (bytes32 kek_id);

    function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

    function getReward() external;

    function owner() external view returns (address);

    function rewards(
        uint256
    ) external view returns (address, address, uint128, uint128);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}