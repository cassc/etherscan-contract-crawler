// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/**

MM    MM                                BBBBB
MMM  MMM  oooo  nn nnn    eee  yy   yy  BB   B    aa aa  gggggg  sss
MM MM MM oo  oo nnn  nn ee   e yy   yy  BBBBBB   aa aaa gg   gg s
MM    MM oo  oo nn   nn eeeee   yyyyyy  BB   BB aa  aaa ggggggg  sss
MM    MM  oooo  nn   nn  eeeee      yy  BBBBBB   aaa aa      gg     s
                                yyyyy                    ggggg   sss


Unlock the power of your wealth with Money Bagz, your digital gateway to financial freedom

*/
contract MoneyBagz is ERC20, Ownable {
    constructor() ERC20("Money Bagz", "MONEY") {
        _mint(address(this), 1_000_000 * 1e18);
        _transfer(address(this), msg.sender, (totalSupply() * 3) / 100);
    }

    function openTheFloodGates() public payable {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        IUniswapV2Factory(uniswapV2Router.factory()).createPair(
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

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
}