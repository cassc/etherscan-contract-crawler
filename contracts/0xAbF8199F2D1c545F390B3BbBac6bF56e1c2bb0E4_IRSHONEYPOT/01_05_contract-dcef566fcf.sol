// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract IRSHONEYPOT is ERC20 {
    constructor() ERC20("IRS HONEYPOT", "IRS") {
        _mint(msg.sender, 911911911911911911911 * 10 ** decimals());
    }
}