// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Context } from "@openzeppelin/contracts/GSN/Context.sol";

abstract contract UtilitiesBase is Context {
    modifier NonZeroAmount(uint256 _amount) {
        require(
            _amount > 0, 
            "Amount must be greater than zero"
        );
        _;
    }

    modifier NonZeroTokenBalance(address _address) {
        require(
            IERC20(_address).balanceOf(address(this)) > 0,
            "No tokens to transfer"
        );
        _;
    }

    modifier NonZeroETHBalance(address _address) {
        require(
            address(this).balance > 0,
            "No ETH to transfer"
        );
        _;
    }

    modifier OnlyOrigin {
        require(
            tx.origin == address(this), 
            "Only origin contract can call this function"
        );
        _;
    }
}