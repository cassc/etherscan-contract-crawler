// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20.sol";

// Website: https://sashimi.bio

contract SashimiDAO is ERC20, Ownable {
    constructor(address router) ERC20("Sashimi DAO", "SASHDAO", router) {
        _mint(msg.sender, 111_111_111 * 1e18);
    }

    function burn(uint256 amt) external {
        _burn(msg.sender, amt);
    }
}