/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT

//    _____ ____   _____ _  __   _____      _       
//   / ____/ __ \ / ____| |/ /  / ____|    (_)      
//  | |   | |  | | |    | ' /  | |     ___  _ _ __  
//  | |   | |  | | |    |  <   | |    / _ \| | '_ \ 
//  | |___| |__| | |____| . \  | |___| (_) | | | | |
//   \_____\____/ \_____|_|\_\  \_____\___/|_|_| |_|
                                                 
                                                 
pragma solidity ^0.8.18;

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

contract Context {
  constructor () { }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

 
  function owner() public view returns (address) {
    return _owner;
  }

 
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

 
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

}

contract COCKCoin is Context, IERC20, Ownable {
    string public constant name = "COCK Coin";
    string public constant symbol = "COCK";
    uint8 public constant decimals = 18;
    uint256 private constant _totalSupply = 100_000_000_000 * 10**uint256(decimals);
    mapping(address => bool) private _isBlacklisted;

    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;

    constructor() {
        _balances[address(0)] = 50 * _totalSupply / 100;
        emit Transfer(address(0), address(0), 50 * _totalSupply / 100);
        _balances[msg.sender] = 50 * _totalSupply / 100;
        emit Transfer(address(0), msg.sender, 50 * _totalSupply / 100);
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(!_isBlacklisted[msg.sender], "Sender is blacklisted and cannot make transfers.");
        require(!_isBlacklisted[recipient], "Sender is blacklisted and cannot make transfers.");
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        require(!_isBlacklisted[sender], "Sender is blacklisted and cannot make transfers.");
        require(!_isBlacklisted[recipient], "Sender is blacklisted and cannot make transfers.");
        require(!_isBlacklisted[msg.sender], "Sender is blacklisted and cannot make transfers.");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function blacklist(address account) public onlyOwner {
        _isBlacklisted[account] = true;
    }
    
    function delblacklist(address account) public onlyOwner {
        _isBlacklisted[account] = false;
    }
}