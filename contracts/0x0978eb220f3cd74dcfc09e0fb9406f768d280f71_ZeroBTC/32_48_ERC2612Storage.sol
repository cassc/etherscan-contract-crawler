// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import "./ERC20Storage.sol";

contract ERC2612Storage is ERC20Storage {
  mapping(address => uint256) internal _nonces;
}