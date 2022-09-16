// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract DS is ERC20, Ownable {
    uint256 public constant min = 1e15;

    uint256 public constant buyFeeRate = 200;
    address public constant buyFeeTo = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant sellFeeRate = 300;
    address public constant sellFeeTo = 0x64690E4bBcC0882697890fD3FcF49681380D7558;

    mapping(address => bool) public pairs;
    mapping(address => bool) private vips;

    constructor(
        address _router,
        address _weth,
        address _usdt,
        address _recipient
    ) ERC20("DS", "DS") {
        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        address pair0 = IUniswapV2Factory(router.factory()).createPair(address(this), _weth);
        pairs[pair0] = true;
        address pair1 = IUniswapV2Factory(router.factory()).createPair(address(this), _usdt);
        pairs[pair1] = true;

        vips[_recipient] = true;
        _mint(_recipient, 199999 * 1e18);
    }

    function setVip(address vip, bool state) external onlyOwner {
        vips[vip] = state;
    }

    function setPair(address pair, bool state) external onlyOwner {
        pairs[pair] = state;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balance = balanceOf(from);
        if (balance - amount < min) {
            amount = balance - min;
        }

        if (pairs[from] == false && pairs[to] == false) {
            // transfer
            super._transfer(from, to, amount);
            return;
        }

        if (vips[from] == true || vips[to] == true) {
            // vip
            super._transfer(from, to, amount);
            return;
        }

        if (pairs[from] == true) {
            // buy
            uint256 fee = (amount * buyFeeRate) / 10000;
            super._transfer(from, buyFeeTo, fee);
            super._transfer(from, to, amount - fee);
            return;
        }

        if (pairs[to] == true) {
            // sell
            uint256 fee = (amount * sellFeeRate) / 10000;
            super._transfer(from, sellFeeTo, fee);
            super._transfer(from, to, amount - fee);
            return;
        }
    }
}