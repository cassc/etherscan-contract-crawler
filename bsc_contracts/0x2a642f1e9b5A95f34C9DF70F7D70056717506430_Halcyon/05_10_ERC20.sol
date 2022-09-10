// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "../vendor/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../vendor/@openzeppelin/contracts/utils/Context.sol";
import "../vendor/@openzeppelin/contracts/access/Ownable.sol";
import "../vendor/@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "hardhat/console.sol";

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable
{
  using SafeMath for uint256;
  
  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => uint256)) internal _allowances;
  
  string internal _name;
  string internal _symbol;
  uint256 internal _decimals;
  uint256 internal _totalSupply;
  uint256 internal TOKENSUPPLY;
  
  constructor(string memory name_, string memory symbol_, uint256 decimals_,
    uint256 totalSupply_)
  {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    TOKENSUPPLY = _totalSupply = totalSupply_ * (10 ** decimals_);
  }
  
  
  // IERC20Metadata
  function name() external view virtual override returns (string memory)
  {
    return _name;
  }
  
  function symbol() external view virtual override returns (string memory)
  {
    return _symbol;
  }
  
  function decimals() external view virtual override returns (uint256)
  {
    return _decimals;
  }
  
  
  // IERC20
  function totalSupply() public view override returns (uint256)
  {
    return _totalSupply;
  }
  
  function balanceOf(address account) public view virtual override returns (uint256)
  {
    return _balances[account];
  }
  
  function transfer(address recipient, uint256 amount) external override returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  
  function allowance(address sender, address spender) external view override returns (uint256)
  {
    return _allowances[sender][spender];
  }
  
  
  // ERC20
  function approve(address spender, uint256 amount) external override returns (bool)
  {
    //save gas (non standard ECR20!)
    if (amount != 0 && _allowances[_msgSender()][spender] >= amount)
      return true;
    
    _approve(_msgSender(), spender, amount);
    return true;
  }
  
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool)
  {
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "Transfer amount exceeds allowance");
    
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), currentAllowance.sub(amount));
    
    return true;
  }
  
  function _transfer(address sender, address recipient, uint256 amount) internal virtual
  {
    require(sender != address(0) && recipient != address(0), "Transfer from/to zero address.");
    require(amount > 0, "Transfer amount is zero.");
    
    uint256 senderBalance = balanceOf(sender);
    require(senderBalance >= amount, "Amount too high.");
    
    _balances[sender] = senderBalance.sub(amount);
    _balances[recipient] += amount;
    
    emit Transfer(sender, recipient, amount);
  }
  
  function _mint(address account, uint256 amount) internal
  {
    require(account != address(0), "Mint to zero address");
    
    //_totalSupply set in constructor, _mint() is used once.
    
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }
  
  function _approve(address sender, address spender, uint256 amount) internal
  {
    require(sender != address(0) && spender != address(0), "Approve zero address.");
    
    _allowances[sender][spender] = amount;
    
    emit Approval(sender, spender, amount);
  }
}