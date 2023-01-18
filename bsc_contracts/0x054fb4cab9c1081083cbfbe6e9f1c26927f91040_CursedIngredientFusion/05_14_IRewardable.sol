// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRewardable {
    function addRewards(address sender, uint256[] memory amount) external;

    function getRewardTokens() external view returns (IERC20Upgradeable[] memory);
}