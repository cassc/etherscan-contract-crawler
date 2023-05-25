/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RollSafeToken {
    string public name = "Roll Safe";
    string public symbol = "ROLL";
    uint256 public totalSupply = 369000000000000000000000000; // 369 billion tokens
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public owner = 0x0e181ae3d82ab45e0e4C5005Bd724A202C5c134A;
    address public publicOwnerWallet = 0x0e181ae3d82ab45e0e4C5005Bd724A202C5c134A; // Your public owner wallet address
    address public cexWallet = 0x8E529ca407832db5dD6A890F7A29303776622615; // CEX listing wallet address
    address public marketingWallet = 0xa02816421A6f8a14eE08eBeA9cf5afb4e090CEe5; // Marketing wallet address

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) external {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, allowance[_from][msg.sender] - _value);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
    }

    function _approve(address _owner, address _spender, uint256 _value) internal {
        allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function distributeLiquidity() external {
        require(msg.sender == owner, "Only the contract owner can distribute liquidity");

        uint256 publicOwnerAmount = (totalSupply * 3) / 100;
        uint256 cexAmount = (totalSupply * 6) / 100;
        uint256 marketingAmount = (totalSupply * 9) / 100;

        _transfer(owner, publicOwnerWallet, publicOwnerAmount);
        _transfer(owner, cexWallet, cexAmount);
        _transfer(owner, marketingWallet, marketingAmount);
    }
}