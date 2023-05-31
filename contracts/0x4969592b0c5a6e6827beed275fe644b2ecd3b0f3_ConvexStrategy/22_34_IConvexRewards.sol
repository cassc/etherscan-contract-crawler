// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

// See https://docs.convexfinance.com/convexfinanceintegration/baserewardpool
interface IConvexRewards {
    // get balance of an address
    function balanceOf(address _account) external returns (uint256);
    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns (bool);
    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
    // Withdraw to curve LP token while also claiming any rewards
    function withdrawAllAndUnwrap(bool claim) external;
    // claim rewards
    function getReward() external returns (bool);
    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);
    //stake a convex tokenized deposit for another address(transferring ownership)
    function stakeFor(address _account, uint256 _amount) external returns (bool);

    // Get amount of pending CRV rewards
    function earned(address account) external view returns (uint256);
}