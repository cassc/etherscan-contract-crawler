// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract POOLL {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    address public admin;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        name = "POOLL";
        symbol = "PL";
        totalSupply = 25020;
        admin = msg.sender;
        balanceOf[admin] = totalSupply;
    }

    function transfer(address _to, uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        require(msg.sender != _to, "Invalid transfer");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
    }

    function mint(address _to, uint256 _amount) public onlyAdmin {
        require(_to != address(0), "Invalid address");

        balanceOf[_to] += _amount;
        totalSupply += _amount;

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function burn(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;

        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }
}