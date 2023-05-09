// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Peter is ERC20, Ownable {
    constructor() ERC20("Peter", "PETER") {
        _mint(msg.sender, 1234567890 * 10 ** decimals());
    }
}