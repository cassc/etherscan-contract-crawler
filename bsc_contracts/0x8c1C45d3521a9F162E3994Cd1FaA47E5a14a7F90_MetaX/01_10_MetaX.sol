// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";

contract MetaX is ERC20, Ownable {
    using SafeMath for uint256;
    address private routerAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private USDTAddr = 0x55d398326f99059fF775485246999027B3197955;
    address private poolAddr = 0x8C744cbaaB8EAA4Fa56bB63aaA6B26E6FEA2F376;
    address private daoAddr = 0x8E969648eD96E4bE56845b3732C29899C2769220;
    address private fundAddr = 0xb14A3869bA7c14db2E40474E3B7d2d274A38dBd1;

    IPancakeRouter02 public uniswapV2Router;
    address public uniswapV2Pair;
    mapping(address => bool) public uniswapPairAddrs;

    constructor() ERC20("MetaX", "MAX") {
        uniswapV2Router = IPancakeRouter02(routerAddr);
        uniswapV2Pair = IPancakeFactory(uniswapV2Router.factory()).createPair(
            address(this),
            USDTAddr
        );
        uniswapPairAddrs[uniswapV2Pair] = true;
        _mint(poolAddr, 210000000 * 10 ** decimals());
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer to the zero amount");
        if (uniswapPairAddrs[from] || uniswapPairAddrs[to]) {
            uint256 poolFee = amount.div(100);
            uint256 daoFee = amount.div(100);
            uint256 fundFee = amount.div(100);
            uint256 _amount = amount.sub(poolFee).sub(daoFee).sub(
                fundFee
            );
            super._transfer(from, poolAddr, poolFee);
            super._transfer(from, daoAddr, daoFee);
            super._transfer(from, fundAddr, fundFee);
            super._transfer(from, to, _amount);
        } else {
            super._transfer(from, to, amount);
        }
    }
}