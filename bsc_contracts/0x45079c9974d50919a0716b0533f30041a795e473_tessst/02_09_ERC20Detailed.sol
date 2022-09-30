// SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.7.4;


import "./IERC20.sol";

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory ERCname,
        string memory ERCsymbol,
        uint8 ERCdecimals
    ) {
        _name = ERCname;
        _symbol = ERCsymbol;
        _decimals = ERCdecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}