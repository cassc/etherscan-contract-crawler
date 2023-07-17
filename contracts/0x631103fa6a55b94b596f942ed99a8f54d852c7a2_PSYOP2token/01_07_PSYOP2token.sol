// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PSYOP2token is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("PSYOP 2.0", "PSYOP2.0") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}