// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.8.0;

interface IConverter {
  function convert(address) external returns (uint256);

  function estimate(uint256) external view returns (uint256);
}