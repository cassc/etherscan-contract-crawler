// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract PeepoToken is ERC20Permit, ERC20Burnable {

    constructor() ERC20("PEEPO", "PEEPO")  ERC20Permit("PEEPO") {
        _mint(msg.sender, 69420000000000 * 1 ether);
    }

}