// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MarvintheMartian is ERC20 {
    uint256 public buyTaxRate = 2; // 2% Tax rate for buy transactions
    uint256 public sellTaxRate = 2; // 2% Tax rate for sell transactions

    address public owner;
    address public taxAddress = 0xD7A4BE21933B3fFb8Bf726825a2a126d77AA1236; // Address to receive tax fees

    uint256 private constant TOTAL_SUPPLY = 280000000 * (10**18); // Total supply of tokens (280 million)

    mapping(address => bool) private _isExcludedFromTax;
    mapping(address => bool) private _isBlacklisted;
    mapping(address => uint256) private _balances;

    constructor() ERC20("MarvintheMartian", "MRVN") {
        owner = msg.sender;
        _mint(owner, TOTAL_SUPPLY); // Mint the total supply to the contract owner
        _isExcludedFromTax[owner] = true; // Owner is excluded from tax fees
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can execute this function");
        _;
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function excludeFromTax(address account, bool exclude) public onlyOwner {
        _isExcludedFromTax[account] = exclude;
    }

    function addToBlacklist(address account) public onlyOwner {
        _isBlacklisted[account] = true;
    }

    function removeFromBlacklist(address account) public onlyOwner {
        _isBlacklisted[account] = false;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    function _calculateTax(uint256 amount, uint256 taxRate) private pure returns (uint256) {
        return (amount * taxRate) / 100;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(!_isBlacklisted[from], "Sender is blacklisted and cannot perform transfers");
        require(!_isBlacklisted[to], "Receiver is blacklisted and cannot receive transfers");

        uint256 taxAmount = 0;

        // Apply buy and sell taxes for non-excluded addresses
        if (!_isExcludedFromTax[from] && !_isExcludedFromTax[to]) {
            if (from == owner) {
                // Collect ETH as sell tax fees
                taxAmount = _calculateTax(amount, sellTaxRate);
                require(address(this).balance >= taxAmount, "Contract does not have enough ETH for sell tax");
                (bool sent, ) = taxAddress.call{value: taxAmount}("");
                require(sent, "Failed to send ETH for sell tax");
            } else if (to == owner) {
                // Collect ETH as buy tax fees
                taxAmount = _calculateTax(amount, buyTaxRate);
                require(address(this).balance >= taxAmount, "Contract does not have enough ETH for buy tax");
                (bool sent, ) = taxAddress.call{value: taxAmount}("");
                require(sent, "Failed to send ETH for buy tax");
            }
        }

        uint256 transferAmount = amount - taxAmount;

        _balances[from] -= amount;
        _balances[to] += transferAmount;

        emit Transfer(from, to, transferAmount);
    }

    receive() external payable {}
}