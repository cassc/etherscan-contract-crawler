// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import './ENSResolver.sol';

abstract contract ENS {
  function resolver(bytes32 node) public view virtual returns (ENSResolver);
}