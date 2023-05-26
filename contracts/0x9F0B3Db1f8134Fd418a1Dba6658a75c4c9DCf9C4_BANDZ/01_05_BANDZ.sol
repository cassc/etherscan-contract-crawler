// liquidity bandz tight as fuck in this bitch
// squeeze it as far as you can mfers
// there is no roadmap, don't ask
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract BANDZ is ERC20 {
  uint256 public holders;
  uint256 public throughput;
  mapping(address => bool) _wasHolder;

  constructor() ERC20('bandz on bandz on bandz', 'BANDZ') {
    _mint(msg.sender, 100_000_000 * 10**18);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    if (!_wasHolder[to]) {
      _wasHolder[to] = true;
      holders++;
    }
    throughput += amount;
    super._transfer(from, to, amount);
  }
}