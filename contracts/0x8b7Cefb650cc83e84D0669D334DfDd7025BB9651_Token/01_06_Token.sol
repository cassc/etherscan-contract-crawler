// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./BaseERC20Token.sol";

contract Token is BaseERC20Token {
    address public cexAddress;
    address public uniswapV2Pair;
    bool public limited;

    // constraints
    uint256 public maxHoldingAmount;

    constructor(
        address _cexAddress
    ) {
        _name = "CHUPE";
        _symbol = "CHUPE";
        _totalSupply = 420_690_000_000_000 * 10 ** decimals();

        maxHoldingAmount = _totalSupply * 1 / 100;
        cexAddress = _cexAddress;

        // coins distribution
        // 93.1% for liquidity
        _balances[msg.sender] = _totalSupply * 931 / 1000;
        emit Transfer(address(0), msg.sender, _totalSupply * 931 / 1000);
        // 6.9% for CEX
        _balances[cexAddress] = _totalSupply * 69 / 1000;
        emit Transfer(address(0), cexAddress, _totalSupply * 69 / 1000);
    }

    function setRules(bool _limited, address _uniswapV2Pair) public onlyOwner {
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Forbid");
        }
    }
}