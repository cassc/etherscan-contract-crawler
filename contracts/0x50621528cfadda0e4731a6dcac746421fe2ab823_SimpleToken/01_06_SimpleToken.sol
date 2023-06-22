// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {ERC20} from "./ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleToken is ERC20, Ownable {
    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _supply);
    }
}