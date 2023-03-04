// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.15;

abstract contract IChainLog {
  function getAddress(bytes32 _key) public view virtual returns (address addr);
}