// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AstraToken is ERC20 {
    constructor(address to) ERC20("ASTRA PROTOCOL", "ASTRA") {
        _mint(to, 10 ** 27);
    }
}