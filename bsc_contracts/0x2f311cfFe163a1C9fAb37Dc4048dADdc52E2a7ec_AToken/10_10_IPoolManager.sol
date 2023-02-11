// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IPoolManager {
    function getTeamLevel(address user) external view returns (uint256);

    function addReawdAmount(uint256 value) external;
    function sendNftReward() external;
}