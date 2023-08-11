// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract DummyMasterToken is ERC20, Ownable {
  constructor() public ERC20('Dummy Master Token', 'DMT') {
    _mint(msg.sender, 1e18);
  }
}