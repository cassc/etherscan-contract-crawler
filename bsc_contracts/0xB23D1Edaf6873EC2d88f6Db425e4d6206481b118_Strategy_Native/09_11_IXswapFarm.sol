// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IXswapFarm {
    function poolLength() external view returns (uint256);

    function userInfo(uint256 _pid, address _address) external view returns (uint256, uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    // View function to see pending CAKEs on frontend.
    // function pendingCake(uint256 _pid, address _user)
    //     external
    //     view
    //     returns (uint256);

    // Deposit LP tokens to the farm for farm's token allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external;
}