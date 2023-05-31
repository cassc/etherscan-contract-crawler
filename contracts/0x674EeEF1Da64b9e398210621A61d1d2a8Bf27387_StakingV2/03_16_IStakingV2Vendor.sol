// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

abstract contract IStakingV2Vendor {

    function setTokenPerBlock(uint256 _tokenPerBlock) public virtual;

    function setTokenPerBlock(uint256 _tokenPerBlock, uint256 _startBlock, uint256 _closeBlock) public virtual;

    function startBlock() external view virtual returns (uint256);

    function closeBlock() external view virtual returns (uint256);

    function setStartBlock(uint256 _startBlock) public virtual;

    function setCloseBlock(uint256 _closeBlock) public virtual;

    function withdrawRemaining(address addr) external virtual;

    function pendingRewards(uint256 pid, address addr) external virtual view returns (uint256);

    function update(uint256 pid, address user, uint256 amount) external virtual;

    function claim(uint256 pid) external virtual returns (uint256);

    function claim(uint256 pid, address addr) external virtual returns (uint256);
}