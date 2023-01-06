// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IFSushiBill is IERC20Metadata {
    error NoClaimableRewards();

    event Deposit(address indexed account, uint256 amount, address indexed beneficiary);
    event Withdraw(address indexed account, uint256 amount, address indexed beneficiary);
    event Checkpoint();
    event UserCheckpoint(address indexed account);
    event ClaimRewards(address indexed account, address indexed beneficiary, uint256 amount);

    function sousChef() external view returns (address);

    function pid() external view returns (uint256);

    function fToken() external view returns (address);

    function points(uint256 week) external view returns (uint256);

    function lastCheckpoint() external view returns (uint256 timestamp);

    function userPoints(address account, uint256 week) external view returns (uint256);

    function userLastCheckpoint(address account) external view returns (uint256 timestamp);

    function claimedRewards(address account) external view returns (uint256);

    function nextClaimableWeek(address account) external view returns (uint256);

    function initialize(uint256 _pid, address _fToken) external;

    function deposit(uint256 amount, address beneficiary) external;

    function withdraw(uint256 amount, address beneficiary) external;

    function claimRewards(address beneficiary) external;

    function checkpoint() external;

    function userCheckpoint(address account) external;
}