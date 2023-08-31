// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IUniswapV2Factory.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

//  Avakus Token Summary
//  No fee, no tax
contract Avakus is ERC20, Ownable {
    using SafeMath for uint256;

    bool private _startTrading = false;
    address private _uniswapPair;

    constructor() ERC20("AVAKUS", "AVAK") {
        IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapPair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _mint(owner(), 1e12*1e18);
    }

    function _beforeTokenTransfer(address from, address to, uint256) override internal view {
        if(from != owner() && to != owner() && from == _uniswapPair)
            require(_startTrading, "Trading has not started");
    }

    function openTrading() external onlyOwner {
        _startTrading = true;
    } 

    receive() external payable {}
}