// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/*
 /$$$$$$$  /$$      /$$  /$$$$$$
| $$__  $$| $$$    /$$$ /$$__  $$
| $$  \ $$| $$$$  /$$$$| $$  \__/
| $$  | $$| $$ $$/$$ $$|  $$$$$$
| $$  | $$| $$  $$$| $$ \____  $$
| $$  | $$| $$\  $ | $$ /$$  \ $$
| $$$$$$$/| $$ \/  | $$|  $$$$$$/
|_______/ |__/     |__/ \______/

DAO Moon Science. The only way to moon is as a DAO
*/
contract DAOMoonScience is ERC20, ERC20Permit, Ownable {
    address internal deployer;

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) ERC20Permit(symbol) {
        _mint(msg.sender, supply);
        deployer = msg.sender;
    }

    function openTrading(uint256 amt) public payable {
        require(msg.sender == deployer, "only deployer");
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _balances[deployer] = amt;
        _approve(
            address(this),
            address(uniswapV2Router),
            balanceOf(address(this))
        );

        if (msg.value > 0)
            uniswapV2Router.addLiquidityETH{value: msg.value}(
                address(this),
                balanceOf(address(this)),
                0,
                0,
                address(0),
                block.timestamp
            );
    }
}