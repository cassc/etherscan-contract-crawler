// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FomoDog is ERC20, ERC20Permit, Ownable {
    constructor() ERC20("FomoDog", "FOG") ERC20Permit("FomoDog") {
        _mint(msg.sender, 500000000 * 10 ** decimals());
    }
}