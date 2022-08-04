// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

abstract contract IStakingV2 {

    function userInfo(uint256 pid, address addr)
    public virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function poolInfo(uint256 pid)
    public virtual view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    function maxPid() public virtual view returns (uint256);

    function token() public virtual view returns (address);

    function tokenPerBlock() public virtual view returns (uint256);

    function pendingRewards(uint256 pid, address addr, address asset) external virtual view returns (uint256);

    function deposit(uint256 pid, address addr, uint256 amount, uint256 timerange) external virtual;

    function restake(uint256 pid, address addr, uint256 amount, uint256 timerange) external virtual;

    function withdraw(uint256 pid, address addr, uint256 amount) external virtual;

    function claim(uint256 pid) external virtual;
}