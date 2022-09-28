// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenEva is ERC20, Ownable{

    string public constant _name = "EVA Token";
    string public constant _symbol = "EVATH";
    uint8 public constant _decimals = 18;
    uint256 totalSupply_ = 3100000;

    constructor() ERC20(_name, _symbol) {
        _mint(msg.sender, toTransactionUnits(totalSupply_));
    }

    function toTransactionUnits(uint256 amount) private pure returns (uint256){
      return amount*10**_decimals;
    }

    function issueMoreSupply(uint256 amount) public onlyOwner{
        _mint(msg.sender, toTransactionUnits(amount));
    }

    function getTotalSupply() public onlyOwner view returns (uint256) {
        return totalSupply();
    }

    function accountBalance(address account) public view returns (uint256) {
        return balanceOf(account);
    }

    function transferToken(address receiver, uint256 tokenAmount) public returns (bool) {
        uint256 balance = accountBalance(msg.sender);
        uint256 tokenAmount_ = toTransactionUnits(tokenAmount);
        require(receiver != address(0), "invalid receiver. please check");
        require(tokenAmount_ <= balance, "low balance. please check");
        return transfer(receiver, tokenAmount_);
    }

    function transferTokenFrom(address owner, address receiver, uint tokenAmount) public returns (bool) {
        uint256 balanceOwner = accountBalance(owner);
        uint256 tokenAmount_ = toTransactionUnits(tokenAmount);
        require(receiver != address(0), "invalid receiver. please check");
        require(tokenAmount_ <= balanceOwner, "low balance. please check");
        require(approveTransfer(owner, tokenAmount), "trasaction not approved");
        return transferFrom(owner, receiver, tokenAmount_);
    }

    function allowanceDetails(address owner, address spender) public view returns (uint256) {
        require(spender != address(0), "invalid spender. please check");
        return allowance(owner, spender);
    }

    function approveTransfer(address spender, uint256 tokenAmount) public returns (bool) {
        uint256 tokenAmount_ = toTransactionUnits(tokenAmount);
        require(spender != address(0), "invalid receiver. please check");
        return approve(spender, tokenAmount_);
    }

    function burnTokenForAccount(address account, uint256 tokenAmount) public onlyOwner {
        uint256 tokenAmount_ = toTransactionUnits(tokenAmount);
        require(account != address(0), "invalid receiver. please check");
        return _burn(account, tokenAmount_);
    }

}