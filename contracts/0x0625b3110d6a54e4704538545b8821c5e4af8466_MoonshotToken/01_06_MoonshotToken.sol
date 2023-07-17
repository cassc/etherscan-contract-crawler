// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20.sol";

/**
 _______  _______  _______  _        _______           _______ _________ _
(       )(  ___  )(  ___  )( (    /|(  ____ \|\     /|(  ___  )\__   __/( )
| () () || (   ) || (   ) ||  \  ( || (    \/| )   ( || (   ) |   ) (   | |
| || || || |   | || |   | ||   \ | || (_____ | (___) || |   | |   | |   | |
| |(_)| || |   | || |   | || (\ \) |(_____  )|  ___  || |   | |   | |   | |
| |   | || |   | || |   | || | \   |      ) || (   ) || |   | |   | |   (_)
| )   ( || (___) || (___) || )  \  |/\____) || )   ( || (___) |   | |    _
|/     \|(_______)(_______)|/    )_)\_______)|/     \|(_______)   )_(   (_)

Cause there is only place to go from here.

*/

contract MoonshotToken is ERC20, Ownable {
    constructor(address router) ERC20("The Moonshot", "MOON", router) {
        _mint(msg.sender, 999_999_999_999 * 1e18);
    }

    function burn(uint256 amt) external {
        _burn(msg.sender, amt);
    }
}