// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Sale.sol";

contract TradingSale is ERC20Sale {
    constructor(address _gpo, address _erc20Token, uint256 _price, address _fundWallet)
        ERC20Sale(_gpo, _erc20Token, "Trading", _price, _fundWallet) {
    }
}