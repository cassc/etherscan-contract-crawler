// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IConvexBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);

    function depositAll(uint256 _pid, bool _stake) external returns(bool);
    //burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);

    function withdrawAll(uint256 _pid) external returns(bool);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
}