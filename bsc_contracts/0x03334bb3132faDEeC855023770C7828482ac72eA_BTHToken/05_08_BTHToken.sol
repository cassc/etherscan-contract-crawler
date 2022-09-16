// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract BTHToken is ERC20 {
    uint256 public constant min = 1e15;

    uint256 public constant buyFeeRate = 200;
    address public constant buyFeeTo = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant sellFeeRate = 300;
    address public constant sellFeeTo = 0x55CFE533c400ACf88C2553fc796700798a570842;

    mapping(address => bool) public pairs;
    mapping(address => bool) private vips;

    constructor(
        address _router,
        address _weth,
        address _usdt
    ) ERC20("BTH Token", "BTH") {
        _mint(0xCAe203591A4E7F451126C3a6c76eD72D24156Bb3, 199999 * 1e18);

        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        address pair0 = IUniswapV2Factory(router.factory()).createPair(address(this), _weth);
        pairs[pair0] = true;
        address pair1 = IUniswapV2Factory(router.factory()).createPair(address(this), _usdt);
        pairs[pair1] = true;

        vips[0xCAe203591A4E7F451126C3a6c76eD72D24156Bb3] = true;
        vips[0xAEcee83E47D3B80b189757254B7Fa7f19aB3E31d] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balance = balanceOf(from);
        if (balance - amount < min) {
            amount = balance - min;
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
            uint256 fee = (amount * buyFeeRate) / 10000;
            super._transfer(from, buyFeeTo, fee);
            super._transfer(from, to, amount - fee);
            return;
        }

        if (pairs[to] == true) {
            uint256 fee = (amount * sellFeeRate) / 10000;
            super._transfer(from, sellFeeTo, fee);
            super._transfer(from, to, amount - fee);
            return;
        }
    }
}