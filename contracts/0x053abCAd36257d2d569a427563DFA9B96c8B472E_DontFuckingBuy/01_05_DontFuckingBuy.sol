// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract DontFuckingBuy is ERC20 {
  constructor() ERC20('Dont Fucking Buy', 'DFB') {
    _mint(msg.sender, 10_000_000 * 10**18);
  }
}