// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckyFuks is ERC20, Ownable {
    constructor() ERC20("LUCKY TOKEN", "LUCKY") {
        _mint(msg.sender, 888000000000 * 1 ether);
    }
}