// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ElementToken is ERC20 {
    constructor() ERC20("CARBON Elements", "ELEMENT") {
        _mint(msg.sender, 1000000000 * 10**18); // Mints 1B CARBON elements
    }
}