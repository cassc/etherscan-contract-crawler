// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.0;

interface IWoolfGen2 {
  function mint(address recipient) external;
  function currentId() external view returns(uint256);
}