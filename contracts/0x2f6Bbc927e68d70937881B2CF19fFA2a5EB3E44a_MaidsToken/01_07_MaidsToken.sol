// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMaidsToken.sol";

error NotOperator();

contract MaidsToken is IMaidsToken, ERC20, Ownable {
    mapping(address => bool) private _operators;

    constructor() ERC20("MAIDS", "MAIDS"){}

    function addOperator(address address_) external onlyOwner {
        _operators[address_] = true;
    }

    function removeOperator(address address_) external onlyOwner {
        _operators[address_] = false;
    }

    function mint(address to_, uint256 amount_) external override {
        if (!_operators[msg.sender]) revert NotOperator();
        _mint(to_, amount_);
    }

    function transferFrom(address from_, address to_, uint256 amount_) public override(IMaidsToken, ERC20) returns (bool) {
        return super.transferFrom(from_, to_, amount_);
    }

    function allowance(address owner_, address spender_) public view override(IMaidsToken, ERC20) returns (uint256) {
        return super.allowance(owner_, spender_);
    }

    function balanceOf(address account_) public view override(IMaidsToken, ERC20) returns (uint256) {
        return super.balanceOf(account_);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_) internal override {
        if (from_ != address(0) && !_operators[from_] && !_operators[to_]) revert NotOperator();
    }
}