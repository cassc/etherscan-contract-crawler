// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BEP20.sol";

contract MUTEFERRIQA is BEP20("MUTEFERRIQA", "MQA") {

  /**
  * @param wallet Address of the wallet, where tokens will be transferred to
  */
  constructor(address wallet) {
    _mint(wallet, uint256(10000000000) * 1 ether);
  }
}
