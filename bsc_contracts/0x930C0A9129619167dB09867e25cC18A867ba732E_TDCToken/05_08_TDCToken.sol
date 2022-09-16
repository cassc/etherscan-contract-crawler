// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract TDCToken is ERC20 {
    mapping(address => bool) private vips;
    mapping(address => bool) private pairs;

    constructor(
        address _router,
        address _wbnb,
        address _usdt
    ) ERC20("TDC Token", "TDC") {
        _mint(0xCAe203591A4E7F451126C3a6c76eD72D24156Bb3, 199999 * 1e18);

        vips[0xCAe203591A4E7F451126C3a6c76eD72D24156Bb3] = true;
        vips[0xAEcee83E47D3B80b189757254B7Fa7f19aB3E31d] = true;

        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        address pair0 = IUniswapV2Factory(router.factory()).createPair(address(this), _wbnb);
        pairs[pair0] = true;
        address pair1 = IUniswapV2Factory(router.factory()).createPair(address(this), _usdt);
        pairs[pair1] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balance = balanceOf(from);
        if (balance - amount < 1e15) {
            amount = balance - 1e15;
        }

        if (pairs[from] == false && pairs[to] == false) {
            super._transfer(from, to, amount);
            return;
        }

        if (vips[from] == true || vips[to] == true) {
            super._transfer(from, to, amount);
            return;
        }

        if (pairs[from] == true) {
            uint256 fee = (amount * 200) / 10000;
            super._transfer(from, 0x000000000000000000000000000000000000dEaD, fee);
            super._transfer(from, to, amount - fee);
            return;
        }

        if (pairs[to] == true) {
            uint256 fee = (amount * 300) / 10000;
            super._transfer(from, 0x55CFE533c400ACf88C2553fc796700798a570842, fee);
            super._transfer(from, to, amount - fee);
            return;
        }
    }
}