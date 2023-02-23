/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TIYB {
    string public name = "TIYB Token";
    string public symbol = "TIYB";
    uint256 public totalSupply = 21000000;
    uint8 public decimals = 18;

    address public marketingWallet = 0x45bf381Ab6f6161788067195a3c7caC9d76C91F9;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        _transfer(_from, _to, _value);
        allowance[_from][msg.sender] -= _value;
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        uint256 fee = _value / 100;
        balanceOf[_from] -= _value;
        balanceOf[_to] += (_value - fee);
        balanceOf[marketingWallet] += fee;
        emit Transfer(_from, _to, _value);
    }
}