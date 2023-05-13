/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "LITRANIUM";
    string public symbol = "LTR";
    uint public decimals = 18;
    
    address public taxRecipient = 0xF879f8Dc080581BCd331DDEDbc934888f20B7D41;
    uint public buyTax = 2;
    uint public sellTax = 2;
    uint public antiSniperTimelock = 15;
    address public tokenOwner = 0xBff0b62e684eF120C7c6c5818aE85b86690bC17a;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        tokenOwner = msg.sender;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        _transfer(from, to, value);
        allowance[from][msg.sender] -= value;
        return true;   
    }
    
    function _transfer(address from, address to, uint value) internal {
        uint taxAmount = 0;
        if (from == tokenOwner) {
            // Buying tokens, apply buy tax
            taxAmount = (value * buyTax) / 100;
        } else if (to == tokenOwner) {
            // Selling tokens, apply sell tax
            taxAmount = (value * sellTax) / 100;
        }
        
        if (taxAmount > 0) {
            balances[tokenOwner] += taxAmount;
            emit Transfer(from, taxRecipient, taxAmount);
            value -= taxAmount;
        }
        
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}