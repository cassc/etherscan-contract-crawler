/**
 *Submitted for verification at Etherscan.io on 2023-05-03
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

contract BongCoin is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    string public tokenLogoURI;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor() {
        name = "BongCoin";
        symbol = "BONG";
        decimals = 18;
        _totalSupply = 420000000 * 10 ** uint(decimals);
        _balances[0xDf828f01e18e09FB452EB102b5eec164Dcf1B8e7] = _totalSupply;
        emit Transfer(address(0), 0xDf828f01e18e09FB452EB102b5eec164Dcf1B8e7, _totalSupply);
        tokenLogoURI = "ipfs://QmSc37Xuu26LFexLDEw2oWqJCtk3iWMo4fMmiuDwg8nbAx";
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[msg.sender], "ERC20: transfer amount exceeds balance");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");
        require(amount <= _allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setTokenLogoURI(string memory logoURI) public {
        tokenLogoURI = logoURI;
    }
}