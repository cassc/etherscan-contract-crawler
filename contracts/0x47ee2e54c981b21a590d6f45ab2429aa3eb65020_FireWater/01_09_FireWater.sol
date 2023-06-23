// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IWETH} from "../interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/*
 Fire/Water is a blockchain experiment on MEV bots fighting each others. The more scarce the supply becomes,
 the crazier trading becomes.
 */
contract FireWater is ERC20, Ownable {
    IUniswapV2Router02 _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _supply);
    }

    function burn(uint256 amt) public {
        _burn(msg.sender, amt);
    }

    function openTrading() public payable {
        _transfer(msg.sender, address(this), balanceOf(msg.sender));

        _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        _uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            msg.sender,
            block.timestamp
        );
    }
}