/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

pragma solidity ^0.8.17;

contract STITHULFERC {
    string public constant name = "STITHULFERC";
    string public constant symbol = "SUFERC";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1094795585;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        totalSupply = 1094795585;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        require(_to != address(0), "Invalid recipient address");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        return true;
    
    }
}