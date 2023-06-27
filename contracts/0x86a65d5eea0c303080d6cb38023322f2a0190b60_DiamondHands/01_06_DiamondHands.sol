// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20.sol";

/**
|   \(_)__ _ _ __  ___ _ _  __| |
 | |) | / _` | '  \/ _ \ ' \/ _` |
 |___/|_\__,_|_|_|_\___/_||_\__,_|
 | || |__ _ _ _  __| |___
 | __ / _` | ' \/ _` (_-<
 |_||_\__,_|_||_\__,_/__/

 Diamond hands only.
*/

contract DiamondHands is ERC20, Ownable {
    constructor(address router) ERC20("Diamond Hands Only", "HODL", router) {
        _mint(msg.sender, 1000_000_000 * 1e18);
    }

    function burn(uint256 amt) external {
        _burn(msg.sender, amt);
    }
}