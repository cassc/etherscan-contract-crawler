// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Bukkake is ERC20 {
    constructor() ERC20("Bukkake", "BKK") {
        _mint(msg.sender, 69 * 10 ** decimals());
    }
}