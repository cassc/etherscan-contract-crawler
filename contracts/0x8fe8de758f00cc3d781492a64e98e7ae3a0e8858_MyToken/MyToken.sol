/**
 *Submitted for verification at Etherscan.io on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
   ______    ___  _____    ______  _____  _____  ______ ___  ____   
 .' ___  | .'   `|_   _|  |_   _ `|_   _||_   _.' ___  |_  ||_  _|  
/ .'   \_|/  .-.  \| |      | | `. \| |    | |/ .'   \_| | |_/ /    
| |   ____| |   | || |   _  | |  | || '    ' || |        |  __'.    
\ `.___]  \  `-'  _| |__/ |_| |_.' / \ \__/ / \ `.___.'\_| |  \ \_  
 `._____.' `.___.|________|______.'   `.__.'   `.____ .|____||____| 
**/          
/**
TWITTER:https://twitter.com/GOLDUCKCOIN
**/
contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public tax;
    address public owner;
    address public taxRecipient;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply, uint256 _tax, address _taxRecipient) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        tax = _tax;
        owner = msg.sender;
        taxRecipient = _taxRecipient;
        
        balanceOf[msg.sender] = totalSupply;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        uint256 taxAmount = _value * tax / 100; 
        uint256 transferAmount = _value - taxAmount; 
        
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[taxRecipient] += taxAmount;
        
        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, taxRecipient, taxAmount);
        
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        
        uint256 taxAmount = _value * tax / 100; 
        uint256 transferAmount = _value - taxAmount; 
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[taxRecipient] += taxAmount;

        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, taxRecipient, taxAmount);
        
        return true;
    }
    
    
    function setTax(uint256 _tax) external onlyOwner {
        require(_tax <= 100, "Tax percentage exceeds limit");
        tax = _tax;
    }
    
   
    function setTaxRecipient(address _taxRecipient) external onlyOwner {
        taxRecipient = _taxRecipient;
    }
    
    
    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }
}