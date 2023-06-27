// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Website: https://sashimi.bio

contract SashimiToken is ERC20, Ownable {
    constructor() ERC20("Sashimi Token", "SASHIMI") {
        _mint(msg.sender, 777_777 * 1e18);
    }
}