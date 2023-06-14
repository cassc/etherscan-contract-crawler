// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract UnagiToken is ERC20, Ownable {
    constructor(uint256 _supply) ERC20("Unagi Token", "UNAGI") {
        _mint(msg.sender, _supply);
    }
}