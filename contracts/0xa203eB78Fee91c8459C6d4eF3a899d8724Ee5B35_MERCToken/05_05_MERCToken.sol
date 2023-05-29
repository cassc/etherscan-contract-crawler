//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MERCToken is ERC20 {
  constructor() ERC20("Mercury Digital Assets", "MERC") {
    _mint(msg.sender, 20000000000 ether);
  }
}