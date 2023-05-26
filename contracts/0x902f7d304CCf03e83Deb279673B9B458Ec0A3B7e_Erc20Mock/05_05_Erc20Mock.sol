// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Erc20Mock is ERC20 {
  constructor() ERC20("MockERC20", "MockERC20") {
    _mint(msg.sender, 1000000 ether);
  }
}