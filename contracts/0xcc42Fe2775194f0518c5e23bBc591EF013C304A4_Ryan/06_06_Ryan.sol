// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ryan is ERC20, Ownable {
    uint256 total_supply = 690420000000 * 10 ** 18;
    constructor() ERC20("RYAN", "RYAN") {
        _mint(msg.sender, total_supply);
    }
}