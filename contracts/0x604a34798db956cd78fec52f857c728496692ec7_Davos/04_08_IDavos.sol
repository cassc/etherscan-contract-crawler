// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IDavos is IERC20MetadataUpgradeable {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}