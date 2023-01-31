/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

pragma solidity ^0.8.0;

contract MintableToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
    }

    function mint(address _to, uint256 _value) public {
        require(msg.sender == address(this), "Only contract owner can mint");
        require(_value > 0, "Cannot mint zero or negative tokens");

        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Cannot transfer to zero address");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
}