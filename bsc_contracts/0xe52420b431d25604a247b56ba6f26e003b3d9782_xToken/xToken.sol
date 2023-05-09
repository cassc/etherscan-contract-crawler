/**
 *Submitted for verification at BscScan.com on 2023-05-08
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

contract xToken is IERC20 {
    string public constant name = "Dumbledore";
    string public constant symbol = "DUMB";
    string public constant tokenImage = "https://imgur.com/kXLuMMF";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner;

    address private constant taxReceiver = 0xF54F118EB3072E44e0BA1B13D9421B8A64869DDb;

    constructor() {
        uint256 initialSupply = 420000000000 * (10 ** uint256(decimals));
        _totalSupply = initialSupply;
        _balances[taxReceiver] = initialSupply;
        emit Transfer(address(0), taxReceiver, initialSupply);

// Send 91% of the total supply to the 0x000000000000000000000000000000000000dEaD address
        uint256 deadBalance = initialSupply * 95 / 100;
        _balances[address(0x000000000000000000000000000000000000dEaD)] = deadBalance;
        _balances[taxReceiver] -= deadBalance;
        emit Transfer(taxReceiver, address(0x000000000000000000000000000000000000dEaD), deadBalance);


    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address ownerAddress, address spender) public view override returns (uint256) {
        return _allowances[ownerAddress][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Insufficient allowance");
        _allowances[sender][msg.sender] = currentAllowance - amount;

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(_balances[sender] >= amount, "Insufficient balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
     }