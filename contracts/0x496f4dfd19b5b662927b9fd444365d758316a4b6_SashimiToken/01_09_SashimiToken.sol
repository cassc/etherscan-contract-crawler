// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {ERC20} from "../ERC20.sol";

// ███████╗ █████╗ ███████╗██╗  ██╗██╗███╗   ███╗██╗    ██████╗  █████╗  ██████╗
// ██╔════╝██╔══██╗██╔════╝██║  ██║██║████╗ ████║██║    ██╔══██╗██╔══██╗██╔═══██╗
// ███████╗███████║███████╗███████║██║██╔████╔██║██║    ██║  ██║███████║██║   ██║
// ╚════██║██╔══██║╚════██║██╔══██║██║██║╚██╔╝██║██║    ██║  ██║██╔══██║██║   ██║
// ███████║██║  ██║███████║██║  ██║██║██║ ╚═╝ ██║██║    ██████╔╝██║  ██║╚██████╔╝
// ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝
//
// One Token to eclipse the DAOs, One Token to outshine the memes, One Token to command the DEXes... and in darkness, bind them.

// Telegram: https://t.me/sashimieth
// Website: https://www.sashimi.bio/

contract SashimiToken is ERC20, Ownable {
    mapping(address => bool) public _allow;
    uint256 public blockStart;

    constructor() ERC20("SashimiDAO", "SASHIMI") {
        _allow[msg.sender] = true;
        _allow[address(this)] = true;
        _allow[address(0)] = true;
        _allow[0x000000000000000000000000000000000000dEaD] = true;
        _mint(address(this), 1_000_000 * 1e18);
    }

    function startTrading() external payable onlyOwner {
        blockStart = block.number;

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

        renounceOwnership();
    }

    function burnSashimi(uint256 amt) external {
        require(_allow[msg.sender], "only admins can burn");
        _burn(msg.sender, amt);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == owner()) return;

        // keep max wallet for 50 blocks
        if (!_allow[to] && block.number < blockStart + 50) {
            require(balanceOf(to) + amount < (totalSupply() * 3) / 100, "!max");
        }
    }
}