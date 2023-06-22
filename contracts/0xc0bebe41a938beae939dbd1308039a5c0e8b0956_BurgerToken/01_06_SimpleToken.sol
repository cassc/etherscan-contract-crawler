// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**

Democratizing MEV sandwich profits to DAO holders, one burger at a time. Stealth Launch.
Website : https://burgerdao.fun/

*/

contract BurgerToken is ERC20, Ownable {
    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _supply);
    }
}