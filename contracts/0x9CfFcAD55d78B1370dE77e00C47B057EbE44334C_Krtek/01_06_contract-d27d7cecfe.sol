// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";

contract Krtek is ERC20, ERC20Burnable {
    constructor() ERC20("Krtek", "KRTEK") {
        _mint(msg.sender, 133713371337 * 10 ** decimals());
    }
}