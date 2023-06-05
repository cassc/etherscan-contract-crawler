// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function onTokenReward(uint256 pid, address user, address recipient, uint256 tokenAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 tokenAmount) external view returns (IERC20[] memory, uint256[] memory);
}