// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

interface ILotManagerV2Unwindable {
  event Unwound(uint256 amount);

  function unwind(uint256 _amount) external returns (uint256 _total);
}