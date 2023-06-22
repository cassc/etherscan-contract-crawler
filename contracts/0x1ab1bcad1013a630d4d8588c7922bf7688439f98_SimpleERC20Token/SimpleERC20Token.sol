/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleERC20Token {
    string public constant name = "gagcoin";
    string public constant symbol = "ggcn";
    uint8 public constant decimals = 18;
    uint public totalSupply = 1000000000000 * 10**decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public owner;
    bool public sellPaused = false;
    address public taxAddress = 0x644c62361Cc4C2Eb4C67612FD55A4379e222fc59;
    uint public constant taxRate = 5;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed _to, uint256 _amount);
    event Burn(address indexed _from, uint256 _amount);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(balances[msg.sender] >= _amount);
        require(!sellPaused || msg.sender == owner);

        uint256 tax = _amount * taxRate / 100;
        balances[msg.sender] -= _amount;
        balances[_to] += _amount - tax;
        balances[taxAddress] += tax;

        emit Transfer(msg.sender, _to, _amount - tax);
        emit Transfer(msg.sender, taxAddress, tax);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount);
        require(!sellPaused || msg.sender == owner);

        uint256 tax = _amount * taxRate / 100;
        balances[_to] += _amount - tax;
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[taxAddress] += tax;

        emit Transfer(_from, _to, _amount - tax);
        emit Transfer(_from, taxAddress, tax);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool success) {
        totalSupply += _amount;
        balances[_to] += _amount;
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function burn(uint256 _amount) public returns (bool success) {
        require(balances[msg.sender] >= _amount);
        totalSupply -= _amount;
        balances[msg.sender] -= _amount;
        emit Burn(msg.sender, _amount);
        return true;
    }

    function setSellPaused(bool _paused) public onlyOwner {
        sellPaused = _paused;
    }
}