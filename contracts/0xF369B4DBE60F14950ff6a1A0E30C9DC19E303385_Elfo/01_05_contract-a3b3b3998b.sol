// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Elfo is ERC20 {
    constructor() ERC20("elfo", "$elfo") {
        _mint(msg.sender, 999999999 * 10 ** decimals());
    }
}