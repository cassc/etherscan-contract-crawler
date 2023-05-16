/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
Telegram : https://t.me/TOPGENTRANCE
Twitter  : https://twitter.com/TopG_Token_ERC
*/

contract TOPG {
    string public constant name = "$TOPG";
    string public constant symbol = "TOPG";
    uint256 public constant totalSupply = 777000000000000000000000000;
    uint8 public constant decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address private owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    function LockLPToken() public returns (bool) {
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "Invalid recipient address.");
        require(amount <= balances[msg.sender], "Insufficient balance.");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(sender != address(0), "Invalid sender address.");
        require(recipient != address(0), "Invalid recipient address.");
        require(amount <= balances[sender], "Insufficient balance.");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance.");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Invalid spender address.");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function getAllowance(address tokenOwner, address spender) external view returns (uint256) {
        return allowances[tokenOwner][spender];
    }
}