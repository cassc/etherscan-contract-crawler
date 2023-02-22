// SPDX-License-Identifier: BUSL-1.1

import "./IUpdateable.sol";

pragma solidity ^0.8.17;

interface IMintable {
  function balance() external view returns (uint256);

  function mint(address to, uint256 amount) external;
}