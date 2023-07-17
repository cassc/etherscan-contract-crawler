// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ADDIST is ERC20 {
    constructor() ERC20("ADDIST", "ADS") {
        _mint(msg.sender, 80000000 * 10 ** decimals());
    }
}