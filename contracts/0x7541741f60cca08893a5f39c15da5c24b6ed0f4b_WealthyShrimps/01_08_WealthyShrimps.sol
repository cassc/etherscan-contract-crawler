// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

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
    address public uniswapV2Pair;

    constructor() ERC20("Wealthy Shrimps", "SHRIMP") {
        _mint(address(this), 1_000_000 * 1e18);
        _transfer(address(this), msg.sender, (totalSupply() * 1) / 100);
    }

    function burnShrimps(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function feedTheShrimp() public payable {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _approve(
            address(this),
            address(uniswapV2Router),
            balanceOf(address(this))
        );

        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            msg.sender,
            block.timestamp
        );

        renounceOwnership();
    }
}