// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Yoda is ERC20 {
    constructor() ERC20("Yoda", "YODA") {
        _mint(msg.sender, 690000000000 * 10 ** decimals());
    }
}