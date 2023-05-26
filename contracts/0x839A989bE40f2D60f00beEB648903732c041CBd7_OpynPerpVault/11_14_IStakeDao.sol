// SPDX-License-Identifier: MIT

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

pragma solidity ^0.7.2;
pragma experimental ABIEncoderV2;

interface IStakeDao {
  function balance() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function depositAll() external;

  function deposit(uint256 amount) external;

  function withdrawAll() external;

  function withdraw(uint256 _shares) external;

  function token() external returns (IERC20);

  function balanceOf(address account) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function getPricePerFullShare() external view returns (uint256);
}