// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Base is ERC20 {
    uint8 private immutable _decimals;
    uint256 public immutable TOKEN_CODE;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 token_code_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        TOKEN_CODE = token_code_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}