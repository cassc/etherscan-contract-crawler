// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract MILLIONTOKEN is ERC20 {
    constructor() ERC20("1 MILLION TOKEN", "1M TOKEN") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}