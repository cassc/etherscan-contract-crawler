// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";

contract Cyanide is ERC20, ERC20Burnable {
    constructor() ERC20("Cyanide", "CHM") {
        _mint(msg.sender, 21000000042069 * 10 ** decimals());
    }
}