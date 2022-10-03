// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDinostaking {
    function deposit(uint256 loop) external payable;

    function depositWithOther(address token, uint256 amount) external;

    function setAutoStaking() external;

    function stake(address account, uint256 amount) external;

    function unstake(address account, uint256 amount) external;

    function claimToEth(address account) external;

    function claimToOther(address account, address targetToken) external;

    function batchRestake() external;
}