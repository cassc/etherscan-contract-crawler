// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./Wrap.sol";

contract HOBERC20 is ERC20, Ownable {
    uint256 public constant min = 0.1 * 1e18;

    uint256 public constant buyFeeRate = 300; // burn
    address public constant buyFeeTo = 0x000000000000000000000000000000000000dEaD;

    uint256 public constant sellFeeRate1 = 300; // add liquidity to HOB/USDT
    uint256 public constant sellFeeRate2 = 300;
    address public sellFeeTo;

    uint256 public threshold = 1 * 1e18;

    Wrap public immutable wrap;

    IUniswapV2Router public immutable router;
    address public immutable usdt;
    address public immutable pair0; // HOB/WBNB
    address public immutable pair1; // HOB/USDT

    address public recipient;

    mapping(address => bool) private vips;

    bool lock;
    modifier Lock() {
        lock = true;
        _;
        lock = false;
    }

    constructor(
        address _router,
        address _wbnb,
        address _usdt,
        address _recipient,
        address _feeTo
    ) ERC20("Hobbit Crypto Quiz", "HOB") {
        _mint(_recipient, 4000000 * 1e18);

        wrap = new Wrap(_usdt);

        router = IUniswapV2Router(_router);
        usdt = _usdt;
        pair0 = IUniswapV2Factory(router.factory()).createPair(address(this), _wbnb);
        pair1 = IUniswapV2Factory(router.factory()).createPair(address(this), _usdt);
        vips[address(this)] = true;
        vips[_recipient] = true;
        recipient = _recipient;
        sellFeeTo = _feeTo;
    }

    function setVip(address vip, bool state) external onlyOwner {
        vips[vip] = state;
    }

    function setSellFeeTo(address to) external onlyOwner {
        sellFeeTo = to;
    }

    function setThreshold(uint256 amount) external onlyOwner {
        threshold = amount;
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

        if (from != pair0 && from != pair1 && lock == false) {
            addLiquidity();
        }

        // vip swap no fee
        if (vips[from] == true || vips[to] == true) {
            super._transfer(from, to, amount);
            return;
        }

        // transfer no fee
        if (from != pair0 && from != pair1 && to != pair0 && to != pair1) {
            super._transfer(from, to, amount);
            return;
        }

        // buy
        if (from == pair0 || from == pair1) {
            uint256 fee = (amount * buyFeeRate) / 10000;
            super._transfer(from, buyFeeTo, fee);
            super._transfer(from, to, amount - fee);
            return;
        }

        // sell
        if (to == pair0 || to == pair1) {
            uint256 fee1 = (amount * sellFeeRate1) / 10000;
            uint256 fee2 = (amount * sellFeeRate2) / 10000;
            super._transfer(from, address(this), fee1);
            super._transfer(from, sellFeeTo, fee1);
            super._transfer(from, to, amount - fee1 - fee2);
            return;
        }
    }

    function addLiquidity() internal Lock {
        uint256 reserve = balanceOf(address(this));
        if (reserve >= threshold) {
            _approve(address(this), address(router), type(uint256).max);
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = usdt;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                reserve / 2,
                0,
                path,
                address(wrap),
                block.timestamp
            );

            wrap.claim();
            IERC20(usdt).approve(address(router), type(uint256).max);
            router.addLiquidity(
                address(this),
                usdt,
                balanceOf(address(this)),
                IERC20(usdt).balanceOf(address(this)),
                0,
                0,
                sellFeeTo,
                block.timestamp
            );
        }
    }

    function claim(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
    }
}