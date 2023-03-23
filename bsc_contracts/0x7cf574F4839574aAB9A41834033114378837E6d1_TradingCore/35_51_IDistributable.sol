// SPDX-License-Identifier: BUSL-1.1

import "./IMintable.sol";
pragma solidity ^0.8.17;

interface IDistributable is IMintable {
  function transferIn(uint256 amount) external;
}