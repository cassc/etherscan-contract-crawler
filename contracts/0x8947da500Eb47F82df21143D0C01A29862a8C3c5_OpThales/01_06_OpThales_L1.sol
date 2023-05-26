// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OpThales is ERC20, Ownable {
    string private __name = "Optimistic Thales Token";
    string private __symbol = "OpTHALES";
    uint8 private constant __decimals = 18;
    uint private constant INITIAL_TOTAL_SUPPLY = 100000000;

    function name() public view override returns (string memory) {
        return __name;
    }

    function symbol() public view override returns (string memory) {
        return __symbol;
    }

    function decimals() public view override returns (uint8) {
        return __decimals;
    }

    constructor() public ERC20(__name, __symbol) {
        _mint(msg.sender, INITIAL_TOTAL_SUPPLY * 1e18);
    }

    function setName(string memory name_) external onlyOwner {
        __name = name_;
        emit NameChanged(name_);
    }

    function setSymbol(string memory symbol_) external onlyOwner {
        __symbol = symbol_;
        emit SymbolChanged(symbol_);
    }
    
    event NameChanged(string name);
    event SymbolChanged(string symbol);
}