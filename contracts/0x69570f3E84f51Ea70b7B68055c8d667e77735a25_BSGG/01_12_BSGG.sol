// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BSGG is ERC20Permit, Ownable {
    constructor() ERC20("Betswap.gg", "BSGG") ERC20Permit("Betswap.gg") {
        _mint(msg.sender, 10000000000000000000000000000);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function burn(uint256 amount) onlyOwner public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}