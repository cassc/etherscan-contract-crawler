// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FuckPoo is ERC20 {
    constructor() ERC20("FUCKPOO", "FKPOO") {
        _mint(msg.sender, 8000000000000 * 10 ** decimals());
    }
}