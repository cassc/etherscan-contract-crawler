// contract/Token.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    constructor() ERC20("MetaCraft", "MCR") {
      _mint(msg.sender, (10 ** 9) * (10 ** decimals()));
    }
}