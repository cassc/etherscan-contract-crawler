/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Boicotcoinbase is IERC20 {
    string public name = "Boicotcoinbase";
    string public symbol = "BCB";
    uint8 public decimals = 18;
    uint256 public override totalSupply = 19990000000 * 10 ** uint256(decimals);
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;
    
    address public marketingWallet = 0x02AB1AE558A2707eF67c0E5231bb0A038D942257;
    uint256 public transactionFeePercent = 1;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        
        uint256 fee = _value * transactionFeePercent / 100;
        uint256 amount = _value - fee;
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += amount;
        balanceOf[marketingWallet] += fee;
        
        emit Transfer(msg.sender, _to, amount);
        emit Transfer(msg.sender, marketingWallet, fee);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
        
        uint256 fee = _value * transactionFeePercent / 100;
        uint256 amount = _value - fee;
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += amount;
        balanceOf[marketingWallet] += fee;
        
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, amount);
        emit Transfer(_from, marketingWallet, fee);
        
        return true;
    }
}