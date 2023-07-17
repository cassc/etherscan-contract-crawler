// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

/**
 ______  __    __  __    __         ______        ______
/      |/  \  /  |/  |  /  |       /      \      /      \
$$$$$$/ $$  \ $$ |$$ |  $$ |      /$$$$$$  |    /$$$$$$  |
  $$ |  $$$  \$$ |$$ |  $$ |      $$____$$ |    $$$  \$$ |
  $$ |  $$$$  $$ |$$ |  $$ |       /    $$/     $$$$  $$ |
  $$ |  $$ $$ $$ |$$ |  $$ |      /$$$$$$/      $$ $$ $$ |
 _$$ |_ $$ |$$$$ |$$ \__$$ |      $$ |_____  __ $$ \$$$$ |
/ $$   |$$ | $$$ |$$    $$/       $$       |/  |$$   $$$/
$$$$$$/ $$/   $$/  $$$$$$/        $$$$$$$$/ $$/  $$$$$$/

*/

contract INU20 is ERC20, Ownable {
    constructor(address uniswapV2Router) ERC20("INU 2.0", "INU2.0") {
        _mint(msg.sender, 1_000_000 * 1e18);
        _uniswapV2Router = uniswapV2Router;
    }

    function burnDogs(uint256 amt) external {
        _burn(msg.sender, amt);
    }

    function startTrading() public payable {
        _approve(
            address(this),
            address(_uniswapV2Router),
            balanceOf(address(this))
        );

        IUniswapV2Router02(_uniswapV2Router).addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            owner(),
            block.timestamp
        );

        renounceOwnership();
    }
}