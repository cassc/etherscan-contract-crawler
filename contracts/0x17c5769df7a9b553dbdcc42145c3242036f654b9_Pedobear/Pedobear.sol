/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pedobear {
    string public name = "Pedobear 2.0";
    string public symbol = "PEDOFTW";
    uint8 public decimals = 18;
    uint256 public constant MAX_SUPPLY = 420000000000000000000000000000;
    address public marketingWallet;
    address public contractOwner;

    uint256 private constant _buyTaxPercentage = 2;
    uint256 private constant _sellTaxPercentage = 2;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        marketingWallet = 0xC9243E947a19152d3CA2E30B1457cc490B43eE83;
        contractOwner = 0xB65b7d8d6D42e09868C86a8eaAe3eDc44eA1eEb1;
        balances[contractOwner] = MAX_SUPPLY;

        emit Transfer(address(0), contractOwner, MAX_SUPPLY);
    }


    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function totalSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");

        uint256 buyTaxAmount = (amount * _buyTaxPercentage) / 100;
        uint256 transferAmount = amount - buyTaxAmount;

        balances[msg.sender] -= amount;
        balances[to] += transferAmount;
        balances[marketingWallet] += buyTaxAmount;

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, marketingWallet, buyTaxAmount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(amount <= balances[from], "Insufficient balance");
        require(amount <= allowances[from][msg.sender], "Allowance exceeded");

        uint256 buyTaxAmount = (amount * _buyTaxPercentage) / 100;
        uint256 transferAmount = amount - buyTaxAmount;

        balances[from] -= amount;
        balances[to] += transferAmount;
        balances[marketingWallet] += buyTaxAmount;
        allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, marketingWallet, buyTaxAmount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}