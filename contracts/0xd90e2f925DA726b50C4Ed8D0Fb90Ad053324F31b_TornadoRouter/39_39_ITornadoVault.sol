// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ITornadoVault {
  function withdrawTorn(address recipient, uint256 amount) external;
}