/**
 *Submitted for verification on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interface for the ERC20 token standard
interface IERC20 {
    // Returns the total supply of the token
    function totalSupply() external view returns (uint256);

    // Returns the balance of the specified account
    function balanceOf(address account) external view returns (uint256);

    // Transfers a specified amount of tokens to a specified recipient
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining allowance of tokens granted to a specified spender by a token owner
    function allowance(address owner, address spender) external view returns (uint256);

    // Approves the specified address to spend the specified amount of tokens on behalf of the msg.sender
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfers the specified amount of tokens from the specified sender to the specified recipient
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Triggered when tokens are transferred from one address to another
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Triggered when the allowance of a spender for a specific owner is set or increased
    event Approval(address indexed owner, address indexed spender, uint256 value);
}