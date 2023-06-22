// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
      uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
  ) external;
}

contract PepeDino is ERC20, Ownable {
  using SafeMath for uint256;

  string private _name = "PepeDino Coin";
  string private _sym = "PEPEDINO";
  uint private _supply = 420_690_000_000_000 ether;

  IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address public immutable uniswapV2Pair;

  bool private swapping;
  address public marketingWallet = address(0x64797Dd3Efd665a1DeC46fbaB7681567097E06A8);

  uint256 public swapTokensAtAmount = 1000 ether;
  uint256 public tradingActiveAt = 0;
  // 33% sales tax for the first 33 minutes
  uint256 public marketingFeeSell = 33;
  // FEE_DURATION = 33 minutes
  uint256 private constant FEE_DURATION = 1980;

  // exlcude from fees
  mapping(address => bool) private _isExcludedFromFees;

  event ExcludeFromFees(address indexed account, bool isExcluded);
  event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

  constructor() ERC20(_name, _sym) {
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

    // exclude from paying fees or having max transaction amount
    excludeFromFees(owner(), true);
    excludeFromFees(marketingWallet, true);
    excludeFromFees(address(this), true);
    excludeFromFees(address(0xdead), true);

    _mint(msg.sender, _supply);
  }

  function enableTrading() external onlyOwner {
    tradingActiveAt = block.timestamp;
  }

  function enableTradingAt(uint _timestamp) external onlyOwner {
    tradingActiveAt = _timestamp;
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
    emit ExcludeFromFees(account, excluded);
  }

  function isExcludedFromFees(address account) public view returns (bool) {
    return _isExcludedFromFees[account];
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
      if (tradingActiveAt == 0 || tradingActiveAt > block.timestamp) {
        require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
      }
      else {
        if(marketingFeeSell != 0 && block.timestamp > tradingActiveAt + FEE_DURATION) {
          marketingFeeSell = 0;
        }
      }
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    if (canSwap && !swapping && to == uniswapV2Pair && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
      swapping = true;
      swapBack();
      swapping = false;
    }

    bool takeFee = !swapping;

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
      takeFee = false;
    }

    uint256 fees = 0;
    // only take fees on buys/sells, do not take on wallet transfers
    if (takeFee) {
      // on sell
      if (to == uniswapV2Pair && marketingFeeSell > 0) {
        fees = amount.mul(marketingFeeSell).div(100);
      }

      if (fees > 0) {
        super._transfer(from, address(this), fees);
      }

      amount = amount.sub(fees);
    }
    super._transfer(from, to, amount);
  }

  function swapBack() private {
    uint256 contractBalance = balanceOf(address(this));
    if (contractBalance == 0) { return; }

    swapTokensForETH(contractBalance);
  }

  function swapTokensForETH(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // any amount of ETH
      path,
      marketingWallet,
      block.timestamp
    );
  }
}