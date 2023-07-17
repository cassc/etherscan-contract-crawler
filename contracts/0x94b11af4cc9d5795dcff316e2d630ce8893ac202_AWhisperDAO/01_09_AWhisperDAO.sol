// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {ERC20} from "../libraries/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

//  __       __  __        __
// /  |  _  /  |/  |      /  |
// $$ | / \ $$ |$$ |____  $$/   _______   ______    ______    ______
// $$ |/$  \$$ |$$      \ /  | /       | /      \  /      \  /      \
// $$ /$$$  $$ |$$$$$$$  |$$ |/$$$$$$$/ /$$$$$$  |/$$$$$$  |/$$$$$$  |
// $$ $$/$$ $$ |$$ |  $$ |$$ |$$      \ $$ |  $$ |$$    $$ |$$ |  $$/
// $$$$/  $$$$ |$$ |  $$ |$$ | $$$$$$  |$$ |__$$ |$$$$$$$$/ $$ |
// $$$/    $$$ |$$ |  $$ |$$ |/     $$/ $$    $$/ $$       |$$ |
// $$/      $$/ $$/   $$/ $$/ $$$$$$$/  $$$$$$$/   $$$$$$$/ $$/
//                                      $$ |
//                                      $$ |
//                                      $$/
//
// Github: https://github.com/whispertome/whisper-protocol
// Telegram: https://t.me/whisperdao
// Website: https://www.whisperdao.com/

contract AWhisperDAO is ERC20 {
    mapping(address => bool) public _allow;
    uint256 public limits;

    constructor(address deployer) ERC20("WhisperDAO", "WISPDAO") {
        _allow[deployer] = true;
        _allow[address(this)] = true;
        _allow[address(0)] = true;
        _allow[0x000000000000000000000000000000000000dEaD] = true;
        _mint(address(this), 1_000_000_000 * 1e18);
    }

    function openTrading() external payable onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        address pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        _allow[pair] = true;

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

        limits = block.number;
        renounceOwnership();
    }

    function _afterTokenTransfer(
        address,
        address to,
        uint256 amt
    ) internal virtual override {
        if (!_allow[to] && block.number < limits + 10)
            require(balanceOf(to) + amt < (totalSupply() * 3) / 100, "!max");
    }

    function burn(uint256 amount) external {
        require(_allow[msg.sender], "only whitelisted can burn");
        _burn(msg.sender, amount);
    }
}