// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./Wrap.sol";

contract BTCDAO is ERC20 {
    uint256 public constant FEE = 100; // 1%
    uint256 public constant BASE = 10000; // 100%
    address public constant BURN = 0x000000000000000000000000000000000000dEaD;

    address public immutable router;
    address public immutable usdt;
    address public immutable pair;
    address public immutable wrap;
    address public immutable team;

    bool private _lock;
    modifier lock() {
        _lock = true;
        _;
        _lock = false;
    }

    constructor(address _to, address _team, address _router, address _usdt) ERC20("BTCDAO", "BTCDAO") {
        _mint(_to, 2100 * 10 ** decimals());

        team = _team;
        router = _router;
        usdt = _usdt;
        pair = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), _usdt);
        wrap = address(new Wrap(usdt));
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (_lock == true) {
            super._transfer(from, to, amount);
            return;
        }

        if (from == pair) {
            uint256 fee = (amount * FEE) / BASE;
            super._transfer(from, BURN, fee);
            super._transfer(from, to, amount - fee);
            return;
        }

        if (to == pair) {
            uint256 fee = (amount * FEE) / BASE;
            super._transfer(from, address(this), fee);
            super._transfer(from, to, amount - fee);
            return;
        }

        if (_lock == false && from != pair) {
            _addLiquidity();
        }

        super._transfer(from, to, amount);
    }

    function _addLiquidity() internal lock {
        uint256 amount = balanceOf(address(this));
        if (amount == 0) return;

        if (IERC20(pair).totalSupply() == 0) return;

        if (allowance(address(this), router) < amount / 2) {
            _approve(address(this), router, type(uint256).max);
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount / 2,
            0,
            path,
            wrap,
            block.timestamp
        );

        Wrap(wrap).claim();

        uint256 amount0 = balanceOf(address(this));
        if (allowance(address(this), router) < amount0) {
            approve(router, type(uint256).max);
        }
        uint256 amount1 = IERC20(usdt).balanceOf(address(this));
        if (IERC20(usdt).allowance(address(this), router) < amount1) {
            IERC20(usdt).approve(router, type(uint256).max);
        }

        IUniswapV2Router02(router).addLiquidity(address(this), usdt, amount0, amount1, 0, 0, team, block.timestamp);
    }
}