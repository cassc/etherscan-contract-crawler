/**
 *Submitted for verification at Etherscan.io on 2023-08-25
*/

// SPDX-License-Identifier: MIT
/*
 *  Telegram: @OnlyFrens
 *  Twitter: @Only_Frens_
 *  Web: https://onlyfrens.tech/
 *  Email: [email protected]
 */

pragma solidity 0.8.20;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {return msg.sender;}
}

contract Ownable is Context {
  address private _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }
  function owner() public view returns (address) {return _owner;}
  modifier onlyOwner() {require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
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

interface IUniswapV2Factory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
}

contract ONLYFRENS is Context, IERC20, Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => uint256) private _lastTxBlock;
  address payable private _taxWallet;
  address payable private _devWallet;

  uint8 private constant _decimals = 8;
  uint256 private constant _tTotal = 100000000 * 10 ** _decimals;
  string private constant _name = unicode"OnlyFrens";
  string private constant _symbol = unicode"ONLYFRENS";
  uint256 public _maxTxAmount = 2000000 * 10 ** _decimals;
  uint256 public _maxWalletSize = 4000000 * 10 ** _decimals;
  uint256 public _taxSwapThreshold = 0 * 10 ** _decimals;
  uint256 public _maxTaxSwap = 500000 * 10 ** _decimals;

  IUniswapV2Router02 private uniswapV2Router;
  address public uniswapV2Pair;
  bool private tradingOpen;
  bool private inSwap = false;
  bool private swapEnabled = false;
  bool private preventMEV = true;

  modifier lockTheSwap() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor(address devWallet) {
    _devWallet = payable(devWallet);
    _taxWallet = payable(_msgSender());
    _balances[_msgSender()] = _tTotal.mul(9).div(10);
    _balances[_devWallet] = _tTotal.mul(1).div(10);

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_devWallet] = true;
    _isExcludedFromFee[_taxWallet] = true;
  }

  function name() public pure returns (string memory) {
    return _name;
  }

  function symbol() public pure returns (string memory) {
    return _symbol;
  }

  function decimals() public pure returns (uint8) {
    return _decimals;
  }

  function totalSupply() public pure override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  ) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) private {
    if (owner == address(0) || spender == address(0)) {
      revert("ERC20: approve from/to the zero address");
    }
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(address from, address to, uint256 amount) private {
    if(from == address(0) || to == address(0)) {revert("ERC20: transfer from/to the zero address");}
    if(amount <= 0) {revert("ERC20: transfer amount must be greater than zero");}
    uint256 taxAmount = 0;
    if (from != owner() && to != owner()) {
      if (preventMEV) {
        if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
          if (_lastTxBlock[tx.origin] == block.number) {revert("Sandwich Attack Detected");}
          _lastTxBlock[tx.origin] = block.number;
        }
      }

      if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
        if (amount > _maxTxAmount) {revert("Exceeds maxTxAmount");}
        if (balanceOf(to) + amount > _maxWalletSize) {revert("Exceeds maxWalletSize");}
      }

      if (to == uniswapV2Pair && from != address(this)) {
        if (amount > _maxTxAmount) {revert("Exceeds maxTxAmount");}
      }

      uint256 contractTokenBalance = balanceOf(address(this));
      if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold) {
        swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
          sendETHToFee(address(this).balance);
        }
      }
      taxAmount = amount.mul(25).div(1000);
    }

    if (taxAmount > 0) {
      _balances[address(this)] = _balances[address(this)].add(taxAmount);
      emit Transfer(from, address(this), taxAmount);
    }
    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(amount.sub(taxAmount));
    emit Transfer(from, to, amount.sub(taxAmount));
  }

  function min(uint256 a, uint256 b) private pure returns (uint256) {
    return (a > b) ? b : a;
  }

  function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
    if (tokenAmount == 0) {return;}
    if (!tradingOpen) {return;}
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function sendETHToFee(uint256 amount) private {
    _taxWallet.transfer(amount);
  }

  function manualSwap() external {
    if (_msgSender() != _taxWallet) {revert("Only tax wallet can manually swap");}
    uint256 tokenBalance = balanceOf(address(this));
    if (tokenBalance > 0) {
      swapTokensForEth(tokenBalance);
    }
    uint256 ethBalance = address(this).balance;
    if (ethBalance > 0) {
      sendETHToFee(ethBalance);
    }
  }

  function removeLimits() external onlyOwner {
    _maxTxAmount = _tTotal;
    _maxWalletSize = _tTotal;
    preventMEV = false;
  }

  function openTrading() external onlyOwner {
    if(tradingOpen) {revert("Trading already open");}
    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    _approve(address(this), address(uniswapV2Router), _tTotal);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    swapEnabled = true;
    tradingOpen = true;
  }

  receive() external payable {}
}