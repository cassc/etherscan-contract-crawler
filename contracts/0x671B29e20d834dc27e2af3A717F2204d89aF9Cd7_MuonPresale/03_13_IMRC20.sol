// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IMRC20 is IERC20, IERC20Metadata{
  function mint(address reveiver, uint256 amount) external;
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
}