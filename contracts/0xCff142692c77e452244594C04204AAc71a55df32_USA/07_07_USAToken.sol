// contracts/USA.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract USA is ERC20Capped, ERC20Burnable {
    address payable public owner;
    uint256 public blockReward;
    uint256 public buyTaxRate;
    uint256 public sellTaxRate;
    uint256 public maxBuyPercentage;

    constructor(uint256 cap, uint256 reward) ERC20("USA", "USA") ERC20Capped(cap * (10 ** decimals())) {
        owner = payable(msg.sender);
        _mint(owner, 71111111110 * (10 ** decimals()));
        blockReward = reward * (10 ** decimals());
        buyTaxRate = 10; // 1% buy tax rate
        sellTaxRate = 99; // 1% sell tax rate
        maxBuyPercentage = 2; // 100% maximum buy percentage
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _mintMinerReward() internal {
        _mint(block.coinbase, blockReward);
    }

    function _applyBuyTax(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0) || recipient == address(0) || sender == block.coinbase) {
            return;
        }

        uint256 totalSupply = totalSupply();
        uint256 maxBuyAmount = totalSupply * maxBuyPercentage / 100;
        uint256 senderBalance = balanceOf(sender);
        // uint256 recipientBalance = balanceOf(recipient);

        if (sender != owner && recipient != owner) {
            require(senderBalance >= amount, "Insufficient balance");
            require(amount <= maxBuyAmount, "Exceeded maximum buy percentage");
        }

        uint256 taxAmount = amount * buyTaxRate / 100;
        _burn(sender, taxAmount);
        _transfer(sender, recipient, amount - taxAmount);

        if (recipient != owner) {
            require(amount <= maxBuyAmount, "Exceeded maximum buy percentage");
        }
    }

    function _applySellTax(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0) || recipient == address(0) || recipient == block.coinbase) {
            return;
        }

        uint256 taxAmount = amount * sellTaxRate / 100;
        _burn(sender, taxAmount);
        _transfer(sender, recipient, amount - taxAmount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override{
        if (from != address(0) && to != block.coinbase && block.coinbase != address(0)) {
            _mintMinerReward();
        }
        super._beforeTokenTransfer(from, to, value);
    }

    function destroy() public onlyOwner {
        selfdestruct(owner);
    }

    function setBlockReward(uint256 reward) public onlyOwner {
        blockReward = reward * (10 ** decimals());
    }

    function setBuyTaxRate(uint256 rate) public onlyOwner {
        require(rate <= 100, "Invalid tax rate");
        buyTaxRate = rate;
    }

    function setSellTaxRate(uint256 rate) public onlyOwner {
        require(rate <= 100, "Invalid tax rate");
        sellTaxRate = rate;
    }

    function setMaxBuyPercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 100, "Invalid percentage");
        maxBuyPercentage = percentage;
    }

    function transferWithoutTax(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

        modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier maxBuyPercentageRestriction(address recipient, uint256 amount) {
        uint256 totalSupply = totalSupply();
        uint256 maxBuyAmount = totalSupply * maxBuyPercentage / 100;
        require(amount <= maxBuyAmount, "Exceeded maximum buy percentage");
        _;
    }

    function transfer(address recipient, uint256 amount) public override maxBuyPercentageRestriction(_msgSender(), amount) returns (bool) {
        _applyBuyTax(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override maxBuyPercentageRestriction(sender, amount) returns (bool) {
        _applyBuyTax(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()) - amount
        );
        return true;
    }

    function sell(address recipient, uint256 amount) public returns (bool) {
        _applySellTax(_msgSender(), recipient, amount);
        return true;
    }
    function renounceOwnership() public onlyOwner {
        owner = payable(address(0));
    }
}