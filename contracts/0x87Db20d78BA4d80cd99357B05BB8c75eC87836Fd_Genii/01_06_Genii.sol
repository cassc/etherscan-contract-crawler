//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Genii is Ownable, ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _totalSupply,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @dev See {ERC20-name}.
     * Returns the name of the token.
     */
    function name() public view override returns(string memory) {
        return _name;
    }

    /**
     * @dev See {ERC20-symbol}.
     * Returns the symbol of the token.
     */
    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    /**
     * @dev See {ERC20-decimals}.
     * Returns the decimals of the token.
     */
    function decimals() public view override returns(uint8) {
        return _decimals;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    function setSymbol(string memory symbol_) external onlyOwner {
        _symbol = symbol_;
    }

    function setDecimals(uint8 decimals_) external onlyOwner {
        _decimals = decimals_;
    }

}