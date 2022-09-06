// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import {IERC20} from './IERC20.sol';

interface IERC20WithPermit is IERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}