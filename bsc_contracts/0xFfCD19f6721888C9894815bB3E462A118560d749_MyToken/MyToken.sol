/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public taxFee; // 买卖税费
    address public taxWallet; // 税收钱包地址
    address public owner; // 合约拥有者地址
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint256 _taxFee,
        address _taxWallet
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        
        setTax(_taxFee, _taxWallet);
    }
    
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        uint256 taxedAmount = calculateTax(_value);
        uint256 amount = _value - taxedAmount;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += amount;
        balanceOf[taxWallet] += taxedAmount;
        
        emit Transfer(msg.sender, _to, amount);
        emit Transfer(msg.sender, taxWallet, taxedAmount);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        
        uint256 taxedAmount = calculateTax(_value);
        uint256 amount = _value - taxedAmount;
        balanceOf[_from] -= _value;
        balanceOf[_to] += amount;
        balanceOf[taxWallet] += taxedAmount;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, amount);
        emit Transfer(_from, taxWallet, taxedAmount);
        emit Approval(_from, msg.sender, allowance[_from][msg.sender]);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0), "Invalid address");
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function calculateTax(uint256 _value) internal view returns (uint256) {
        return (_value * taxFee) / 100;
    }
    
    function setTax(uint256 _taxFee, address _taxWallet) public onlyOwner {
        taxFee = _taxFee;
        taxWallet = _taxWallet;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}