/**
 *Submitted for verification at Etherscan.io on 2023-05-17
*/

// SPDX-License-Identifier: UNLICENSED 
pragma solidity 0.8.15;

// Define interface for compliance with ERC20 standard 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Define contract for GOKU SUN token  
contract BEAR is IERC20 {
    string public constant name = "BEAR Coin";
    string public constant symbol = "BEAR";
    uint8 public constant decimals = 18;  
    uint public constant totalSupply = 999000000000 * 10**18; 
    
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;

    constructor() {
        _balances[msg.sender] = totalSupply;
    }  
    
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account]; 
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }  

    function transfer(address recipient, uint amount) public override returns (bool) {
        require(_balances[msg.sender] >= amount, 'ERR_OWN_BALANCE_NOT_ENOUGH');
        require(msg.sender != recipient, 'ERR_SENDER_IS_RECEIVER');
        _balances[msg.sender] -= amount;                      
        _balances[recipient] += amount;                       
        emit Transfer(msg.sender, recipient, amount);              
        return true;                                  
    }
    
    function approve(address spender, uint amount) public override returns (bool) {  
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);         
        return true;
    } 
    
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        require(_balances[sender] >= amount, 'ERR_FROM_BALANCE_NOT_ENOUGH');
        require(_allowances[sender][msg.sender] >= amount, 'ERR_ALLOWANCE_NOT_ENOUGH');
        _balances[sender] -= amount;                          
        _allowances[sender][msg.sender] -= amount;              
        _balances[recipient] += amount;                      
        emit Transfer(sender, recipient, amount);                 
        return true;
    }
}