// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract PSYOP is ERC20, ERC20Burnable {
    constructor() ERC20("PSYOP", "PSYOP") {
        _mint(msg.sender, 555000000000 * 10 ** decimals());
    }
}