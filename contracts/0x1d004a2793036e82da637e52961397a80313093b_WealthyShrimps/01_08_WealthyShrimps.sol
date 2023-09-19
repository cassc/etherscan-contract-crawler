// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/**
 _ _ _         _ _   _          _____ _       _
| | | |___ ___| | |_| |_ _ _   |   __| |_ ___|_|_____ ___ ___
| | | | -_| .'| |  _|   | | |  |__   |   |  _| |     | . |_ -|
|_____|___|__,|_|_| |_|_|_  |  |_____|_|_|_| |_|_|_|_|  _|___|
                        |___|                        |_|
Navigating the waves of crypto wealth. 100k tokens only. 100k shrimps.

*/
contract WealthyShrimps is ERC20, Ownable {
    constructor() ERC20("Wealthy Shrimps", "SHRIMP") {
        _mint(msg.sender, 100_000 * 1e18);
    }

    function burnShrimp(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
}