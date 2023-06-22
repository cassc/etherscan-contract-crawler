// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * One Token to eclipse the DAOs, One Token to outshine the memes, One Token to command the DEXes... and in darkness, bind them. DEX Stealth launch.
 * Website : https://www.unagitoken.com/
 */

contract UnagiToken is ERC20, Ownable {
    constructor(uint256 _supply) ERC20("Unagi Token", "UNAGI") {
        _mint(msg.sender, _supply);
    }
}