/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract BscToken {
    // Mapping of addresses to balances.
    mapping(address => uint256) private balances;

    // Mapping of addresses to mappings of addresses to allowances.
    mapping(address => mapping(address => uint256)) private allowance;

    // The total supply of tokens.
    uint256 public totalSupply = 350000000 * 10 ** 18;

    // The name of the token.
    string public name = "BITSILCO";

    // The symbol of the token.
    string public symbol = "BSC";

    // The number of decimals to use for the token.
    uint8 public decimals = 18;

    // The URL of the token's image.
    string public imageUrl;

    // The fixed price of a token.
    uint256 public tokenPrice = 0.0002 ether; // Set your desired fixed price here

    // Event emitted when tokens are transferred.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    // Event emitted when an allowance is granted.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Constructor.
    constructor() {
        // Initialize the balances mapping.
        balances[msg.sender] = totalSupply;
    }

    // Get the balance of an account.
    function balanceOf(address owner) public view returns(uint256) {
        // Return the balance of the specified account.
        return balances[owner];
    }

    // Transfer tokens to an account.
    function transfer(address to, uint256 value) public returns(bool) {
        // Check if the sender has enough tokens.
        require(balanceOf(msg.sender) >= value, "Insufficient balance");

        // Transfer the tokens.
        _transfer(msg.sender, to, value);

        // Return true.
        return true;
    }

    // Transfer tokens from one account to another, with approval.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns(bool) {
        // Check if the sender has enough tokens.
        require(balanceOf(from) >= value, "Insufficient balance");

        // Check if the sender has approved the transfer.
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        // Transfer the tokens.
        _transfer(from, to, value);

        // Update the allowance.
        allowance[from][msg.sender] -= value;

        // Return true.
        return true;
    }

    // Grant an allowance to an account.
    function approve(address spender, uint256 value) public returns(bool) {
        // Update the allowance.
        _approve(msg.sender, spender, value);

        // Return true.
        return true;
    }

    // Set the image URL.
    function setImageUrl(string memory url) public {
        // Set the image URL.
        imageUrl = url;
    }

    // Internal function to transfer tokens.
    function _transfer(address from, address to, uint256 value) internal {
        // Decrease the balance of the sender.
        balances[from] -= value;

        // Increase the balance of the recipient.
        balances[to] += value;

        // Emit a transfer event.
        emit Transfer(from, to, value);
    }

    // Internal function to approve an allowance.
    function _approve(address owner, address spender, uint256 value) internal {
        // Update the allowance.
        allowance[owner][spender] = value;
    }
}