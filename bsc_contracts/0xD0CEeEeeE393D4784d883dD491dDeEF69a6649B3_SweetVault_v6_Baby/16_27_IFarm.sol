// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IFarm {
    function poolLength() external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pending(uint256 _pid, address _user) external view returns (uint256);
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function pendingBSW(uint256 _pid, address _user) external view returns (uint256);
    function pendingEarnings(uint256 _pid, address _user) external view returns (uint256);
    function pendingPACOCA(uint256 _pid, address _user) external view returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external;
    function deposit(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;
    function deposit(uint256 _pid, uint256 _amount, address _referrer) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount, bool _withdrawRewards) external;

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) external;

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}