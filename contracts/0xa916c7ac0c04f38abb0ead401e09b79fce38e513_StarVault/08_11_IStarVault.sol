// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';
import {LibStarVault} from '../libraries/LibStarVault.sol';
import {Errors} from '../libraries/Errors.sol';

interface IStarVault {
  event PartnerWithdraw(address indexed partner, address indexed token, uint256 amount);

  function partnerTokens(address partner) external view returns (address[] memory tokens_);

  function partnerTokenBalance(address partner, address token) external view returns (uint256);

  function partnerWithdraw(address token) external;

  function ownerWithdraw(address token, uint256 amount, address payable to) external;
}