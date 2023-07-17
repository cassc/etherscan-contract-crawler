// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

contract Tron20 is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        address lp
    ) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 * 1e18);
        _lp = lp;
    }
}