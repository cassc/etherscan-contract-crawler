// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

contract BEN20 is ERC20, Ownable {
    mapping(address => bool) public _whitelist;
    uint256 public maxPerWallet;

    constructor() ERC20("BEN 2.0", "BEN 2.0") {
        _whitelist[msg.sender] = true;
        _whitelist[address(this)] = true;
        _mint(address(this), 69_420_000 * 1e18);
        maxPerWallet = (totalSupply() * 3) / 100;
    }

    function openTrading() external payable onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        _whitelist[uniswapV2Pair] = true;

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
            owner(),
            block.timestamp
        );

        renounceOwnership();
    }

    function burn(uint256 amt) external {
        require(_whitelist[msg.sender]);
        _burn(msg.sender, amt);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == owner()) return;
        if (!_whitelist[to]) {
            // no more than 3% of the supply per wallet
            require(balanceOf(to) + amount < maxPerWallet, "max wallet");
        }
    }
}