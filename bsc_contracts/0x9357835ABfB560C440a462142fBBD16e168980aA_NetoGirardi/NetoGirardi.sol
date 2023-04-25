/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract NetoGirardi {
    
    string public constant NAME = "NetoGirardi";
    string public constant SYMBOL = "NGI";
    uint8 public constant DECIMALS = 18;
    uint256 public constant TOTAL_SUPPLY = 21000000 * (10 ** uint256(DECIMALS));
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    constructor() {
        _balances[msg.sender] = TOTAL_SUPPLY;
    }
    
    function name() public pure returns (string memory) {
        return NAME;
    }
    
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }
    
    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "NetoGirardi: transfer from the zero address");
        require(recipient != address(0), "NetoGirardi: transfer to the zero address");
        require(_balances[sender] >= amount, "NetoGirardi: transfer amount exceeds balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "NetoGirardi: approve from the zero address");
        require(spender != address(0), "NetoGirardi: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}