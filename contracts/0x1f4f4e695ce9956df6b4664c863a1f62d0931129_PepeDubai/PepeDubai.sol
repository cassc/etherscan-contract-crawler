/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

/**

 /$$$$$$$            /$$                 /$$
| $$__  $$          | $$                |__/
| $$  \ $$ /$$   /$$| $$$$$$$   /$$$$$$  /$$
| $$  | $$| $$  | $$| $$__  $$ |____  $$| $$
| $$  | $$| $$  | $$| $$  \ $$  /$$$$$$$| $$
| $$  | $$| $$  | $$| $$  | $$ /$$__  $$| $$
| $$$$$$$/|  $$$$$$/| $$$$$$$/|  $$$$$$$| $$
|_______/  \______/ |_______/  \_______/|__/
                                            
  */                                          
                                            
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract PepeDubai {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string private _name = "Pepe Dubai";
    string private _symbol = "$Pepe Dubai";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 690_000_000_000_000 * 1e18;

    // ERC20 STANDARD
    function name() public view returns (string memory) { return _name; }
    function decimals() public view returns (uint8) { return _decimals; }
    function symbol() public view returns (string memory) { return _symbol; }
    function totalSupply() public view returns (uint256) { return(_totalSupply); }
    function balanceOf(address who) public view returns (uint256) { return (_balances[who]); }
    function allowance(address owner, address spender) public view returns (uint256) { return _allowances[owner][spender]; }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() { _balances[msg.sender] = _totalSupply; }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance.");
        require(recipient != address(0), "Use burn function.");
        require(amount >= 0, "Cannot send 0 tokens.");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Insufficient allowance.");
        _allowances[sender][msg.sender] -= amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function burn(uint256 coins) external {
        address user = msg.sender;
        require(balanceOf(user) / 1e18 >= coins, "Not enough tokens.");
        uint256 amount = coins * 1e18;
        _balances[user] -= amount;
        _totalSupply -= amount;
        emit Transfer(user, address(0), amount);
    }
}