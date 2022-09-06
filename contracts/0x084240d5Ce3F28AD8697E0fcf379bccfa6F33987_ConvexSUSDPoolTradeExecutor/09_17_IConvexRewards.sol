/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

//sample convex reward contracts interface
interface IConvexRewards {
    // pid of pool
    function pid() external view returns (uint256);

    // earned rewards
    function earned(address account) external view returns (uint256);

    //get balance of an address
    function balanceOf(address _account) external view returns (uint256);

    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        external
        returns (bool);

    //claim rewards
    function getReward() external returns (bool);

    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account, uint256 _amount)
        external
        returns (bool);

    function stakeAll() external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;
}