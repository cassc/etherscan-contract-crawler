// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20.sol";

contract BullRunToken is ERC20, Ownable {
    constructor(address router) ERC20("The Bull Run", "BULL", router) {
        _mint(msg.sender, 100_000_000 * 1e18);
    }
}