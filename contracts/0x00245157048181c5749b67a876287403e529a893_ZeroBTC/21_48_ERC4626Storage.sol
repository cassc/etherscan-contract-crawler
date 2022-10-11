// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC2612Storage.sol";
import "./ReentrancyGuardStorage.sol";

contract ERC4626Storage is ERC2612Storage, ReentrancyGuardStorage {
  // maps user => authorized
  mapping(address => bool) internal _authorized;
}