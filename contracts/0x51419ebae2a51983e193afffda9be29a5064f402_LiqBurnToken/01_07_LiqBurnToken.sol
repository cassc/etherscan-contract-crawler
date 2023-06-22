// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {ERC20} from "./ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

contract LiqBurnToken is ERC20, Ownable {
    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        _mint(address(this), _supply);
    }

    receive() external payable {}

    // add liq and burn everything
    function openTrading() external payable {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // renounce ownership
        _transferOwnership(address(0));

        // add and burn liq
        _approve(
            address(this),
            address(_uniswapV2Router),
            balanceOf(address(this))
        );

        _uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            balanceOf(address(this)),
            balanceOf(address(this)),
            msg.value,
            address(this),
            block.timestamp
        );
    }
}