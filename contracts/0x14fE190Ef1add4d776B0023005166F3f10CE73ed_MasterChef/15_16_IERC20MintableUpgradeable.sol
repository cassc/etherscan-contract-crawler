// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20MintableUpgradeable is IERC20Upgradeable {
  /**
    * @dev Mints new token to a user address
  */
  function mint(address toUser, uint256 amount) external;
}