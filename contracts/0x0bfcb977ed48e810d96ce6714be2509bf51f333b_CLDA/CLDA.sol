/**
 *Submitted for verification at Etherscan.io on 2023-06-22
*/

pragma solidity ^0.8.0;

contract CLDA {
    string public name = "CLDA";
    string public symbol = "CLDA";
    uint256 public totalSupply = 1000000000000 * 10**18; // 總發行量（注意：18表示小數位數）
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function buyTokens(uint256 amount) external payable {
        require(amount > 0, "Amount should be greater than zero");
        require(msg.value > 0, "Insufficient funds");

        uint256 tokens = amount * 10**decimals;
        require(balanceOf[msg.sender] + tokens >= balanceOf[msg.sender], "Balance overflow");

        balanceOf[msg.sender] += tokens;
        totalSupply += tokens;

        emit Transfer(address(0), msg.sender, tokens);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }
}