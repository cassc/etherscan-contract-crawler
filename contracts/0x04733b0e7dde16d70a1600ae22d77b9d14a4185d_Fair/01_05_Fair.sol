// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fair is ERC20 {
    constructor() ERC20("Fair", "FAIR") {
        _mint(msg.sender, 100000000 * (10 ** 18));
    }
}