// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

// See https://docs.convexfinance.com/convexfinanceintegration/booster

interface IConvexBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function poolLength() external returns (uint256);
    function poolInfo(uint256 _pid) external returns (PoolInfo memory);
    function depositAll(uint256 _pid, bool _stake) external returns (bool);
    function crv() external returns (address);
}