// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';

contract Bottle is ERC20 {
constructor() ERC20('Bottled Water', 'bwater') {
     _mint(msg.sender, 100000000 * 10 ** 18);
  }
}