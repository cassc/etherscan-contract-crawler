// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/**

 ________  __                        _______             __  __        _______
/        |/  |                      /       \           /  |/  |      /       \
$$$$$$$$/ $$ |____    ______        $$$$$$$  | __    __ $$ |$$ |      $$$$$$$  | __    __  _______
   $$ |   $$      \  /      \       $$ |__$$ |/  |  /  |$$ |$$ |      $$ |__$$ |/  |  /  |/       \
   $$ |   $$$$$$$  |/$$$$$$  |      $$    $$< $$ |  $$ |$$ |$$ |      $$    $$< $$ |  $$ |$$$$$$$  |
   $$ |   $$ |  $$ |$$    $$ |      $$$$$$$  |$$ |  $$ |$$ |$$ |      $$$$$$$  |$$ |  $$ |$$ |  $$ |
   $$ |   $$ |  $$ |$$$$$$$$/       $$ |__$$ |$$ \__$$ |$$ |$$ |      $$ |  $$ |$$ \__$$ |$$ |  $$ |
   $$ |   $$ |  $$ |$$       |      $$    $$/ $$    $$/ $$ |$$ |      $$ |  $$ |$$    $$/ $$ |  $$ |
   $$/    $$/   $$/  $$$$$$$/       $$$$$$$/   $$$$$$/  $$/ $$/       $$/   $$/  $$$$$$/  $$/   $$/

The bull run is back!

*/
contract TheBullRun is ERC20, Ownable {
    constructor() ERC20("The Bull Run", "BULLRUN") {
        _mint(address(this), 69_69_69_69 * 1e18);
        _transfer(address(this), msg.sender, (totalSupply() * 4) / 100);
    }

    function burnBaby(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function openTrading() public payable {
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
}