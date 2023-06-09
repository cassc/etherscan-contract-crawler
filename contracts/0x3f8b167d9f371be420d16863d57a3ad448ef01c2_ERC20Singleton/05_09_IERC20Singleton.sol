// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Singleton {
  function initialize(
    bytes calldata _name,
    bytes calldata _symbol,
    address _owner
  ) external;

  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;
}