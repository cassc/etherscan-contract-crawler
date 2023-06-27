// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20.sol";

// Website: https://www.badluck.wtf/

contract BadLuckBrian is ERC20, Ownable {
    constructor(address router) ERC20("Bad Luck Brian", "BADBRI", router) {
        _mint(msg.sender, 6969696969 * 1e18);
    }

    function burn(uint256 amt) external {
        _burn(msg.sender, amt);
    }
}