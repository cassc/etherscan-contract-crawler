// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { SafeMath } from './libs/SafeMath.sol';
import { ERC20 } from './libs/ERC20.sol';

import { IUniswapV2Router02 } from './interfaces/IUniswapV2Router02.sol';
import { IUniswapV2Factory } from './interfaces/IUniswapV2Factory.sol';
import { IERC20 } from './interfaces/IERC20.sol';

contract COINBOT is ERC20 {
  using SafeMath for uint256;

  bool private swapping;
  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;

  address public revShareAddress;
  address public teamAddress;

  uint256 public maxTransactionAmount;
  uint256 public swapTokensAtAmount;
  uint256 public maxWallet;

  bool public limitsInEffect = true;
  bool public tradingActive = false;
  bool public swapBackEnabled = false;

  bool public banCapabilityRenounced = false;
  mapping(address => bool) banned;

  uint256 public tradingTotalFees;
  uint256 public tradingRevShareFee;
  uint256 public tradingLiquidityFee;
  uint256 public tradingTeamFee;

  uint256 public tokensForRevShare;
  uint256 public tokensForLiquidity;
  uint256 public tokensForTeam;

  // exclude from fees and max transaction amount
  mapping(address => bool) private _isExcludedFromFees;
  mapping(address => bool) public _isExcludedMaxTransactionAmount;

  // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount
  mapping(address => bool) public aMMPairs;

  event SetAMMPair(address indexed pair, bool indexed value);

  event revShareAddressUpdated(address indexed newAddress, address indexed oldAddress);

  event teamAddressUpdated(address indexed newAddress, address indexed oldAddress);

  event SwapToLP(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

  constructor(address uniswapRouter) ERC20('CoinBot', 'COINBT') {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    uint256 _tradingRevShareFee = 0;
    uint256 _tradingLiquidityFee = 1;
    uint256 _tradingTeamFee = 4;

    uint256 totalSupply = 1_000_000 * 1e18;

    maxTransactionAmount = 10_000 * 1e18; // 1%
    maxWallet = 50_000 * 1e18; // 5%
    swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05%

    tradingRevShareFee = _tradingRevShareFee;
    tradingLiquidityFee = _tradingLiquidityFee;
    tradingTeamFee = _tradingTeamFee;
    tradingTotalFees = tradingRevShareFee + tradingLiquidityFee + tradingTeamFee;

    revShareAddress = address(0x0185c185007a3099480a3D929944a805141C67CA);
    teamAddress = owner(); // set as team wallet

    _isExcludedMaxTransactionAmount[uniswapRouter] = true;
    _isExcludedMaxTransactionAmount[uniswapV2Pair] = true;
    _setAMMPair(address(uniswapV2Pair), true);
    _excludeFromRules(owner());
    _excludeFromRules(address(this));
    _excludeFromRules(address(0xdead));

    // _mint is an internal function in ERC20.sol that is only called here, once.
    _mint(msg.sender, totalSupply);
  }

  receive() external payable {}

  // once enabled, can never be turned off
  function enableTrading() external onlyOwner {
    tradingActive = true;
    swapBackEnabled = true;
  }

  // remove limits after token is stable
  function removeLimits() external onlyOwner returns (bool) {
    limitsInEffect = false;
    return true;
  }

  // target amount to trigger swap back
  function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool) {
    require(
      newAmount >= (totalSupply() * 1) / 100000,
      'Swap amount cannot be lower than 0.001% total supply.'
    );

    require(
      newAmount <= (totalSupply() * 5) / 1000,
      'Swap amount cannot be higher than 0.5% total supply.'
    );

    swapTokensAtAmount = newAmount;
    return true;
  }

  function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
    require(
      newNum >= ((totalSupply() * 5) / 1000) / 1e18,
      'Cannot set maxTransactionAmount lower than 0.5%'
    );
    maxTransactionAmount = newNum * (10 ** 18);
  }

  function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
    require(newNum >= ((totalSupply() * 10) / 1000) / 1e18, 'Cannot set maxWallet lower than 1.0%');
    maxWallet = newNum * (10 ** 18);
  }
  
  // devs are initially excluded from fees
  // once we are ready to remove limits, we should have the vault created first
  // then we can turn off the limits and renounce the privilege granting capability
  function excludeFromFees(address _address, bool value) external onlyOwner {
    require(limitsInEffect, 'Cannot grant privileges after limits have been removed.');
    _isExcludedFromFees[_address] = value;
  }

  // should only be used to add a staking vault, before limits are removed
  function excludeFromRules(address _address) external onlyOwner {
    require(limitsInEffect, 'Cannot grant privileges after limits have been removed.');
    _excludeFromRules(_address);
  }

  // called in relevant methods, including constructor
  function _excludeFromRules(address _address) internal {
    _isExcludedFromFees[_address] = true;
    _isExcludedMaxTransactionAmount[_address] = true;
  }

  function updateTradingFees(
    uint256 _revShareFee,
    uint256 _liquidityFee,
    uint256 _teamFee
  ) external onlyOwner {
    tradingRevShareFee = _revShareFee;
    tradingLiquidityFee = _liquidityFee;
    tradingTeamFee = _teamFee;
    tradingTotalFees = tradingRevShareFee + tradingLiquidityFee + tradingTeamFee;

    require(tradingTeamFee <= tradingRevShareFee, 'teamFee cannot be greater than revShareFee.');
    require(tradingTotalFees <= 5, 'Buy fees must be <= 5.');
  }

  function setAMMPair(address pair, bool value) external onlyOwner {
    require(pair != uniswapV2Pair, 'The pair cannot be removed from aMMPairs');
    _setAMMPair(pair, value);
  }

  function _setAMMPair(address pair, bool value) private {
    aMMPairs[pair] = value;
    _isExcludedMaxTransactionAmount[pair] = value;
    emit SetAMMPair(pair, value);
  }

  function updateRevShareAddress(address newRevShareAddress) external onlyOwner {
    emit revShareAddressUpdated(newRevShareAddress, revShareAddress);
    _excludeFromRules(newRevShareAddress);
    revShareAddress = newRevShareAddress;
  }

  function updateTeamAddress(address newAddress) external onlyOwner {
    emit teamAddressUpdated(newAddress, teamAddress);
    _excludeFromRules(newAddress);
    teamAddress = newAddress;
  }

  function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(!banned[from], 'Sender banned');
    require(!banned[to], 'Receiver banned');

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    if (limitsInEffect) {
      if (
        from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping
      ) {
        if (!tradingActive) {
          require(_isExcludedFromFees[from] || _isExcludedFromFees[to], 'Trading is not active.');
        }

        // when buy
        if (aMMPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
          require(
            amount <= maxTransactionAmount,
            'Buy transfer amount exceeds the maxTransactionAmount.'
          );
          require(amount + balanceOf(to) <= maxWallet, 'Max wallet exceeded');
        }
        // when sell
        else if (aMMPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
          require(
            amount <= maxTransactionAmount,
            'Sell transfer amount exceeds the maxTransactionAmount.'
          );
        } else if (!_isExcludedMaxTransactionAmount[to]) {
          require(amount + balanceOf(to) <= maxWallet, 'Max wallet exceeded');
        }
      }
    }

    uint256 contractTokenBalance = balanceOf(address(this));
    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    if (
      canSwap &&
      swapBackEnabled &&
      !swapping &&
      !aMMPairs[from] &&
      !_isExcludedFromFees[from] &&
      !_isExcludedFromFees[to]
    ) {
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
    // only take fees on trading, do not take on wallet transfers
    if (takeFee) {
      // trading fees
      if ((aMMPairs[to] || aMMPairs[from]) && tradingTotalFees > 0) {
        fees = amount.mul(tradingTotalFees).div(100);
        tokensForLiquidity += (fees * tradingLiquidityFee) / tradingTotalFees;
        tokensForTeam += (fees * tradingTeamFee) / tradingTotalFees;
        tokensForRevShare += (fees * tradingRevShareFee) / tradingTotalFees;
      }

      if (fees > 0) {
        super._transfer(from, address(this), fees);
      }

      amount -= fees;
    }

    super._transfer(from, to, amount);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // safe because the token swap fees make most MEV unprofitable
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }

  function swapBack() private {
    uint256 contractBalance = balanceOf(address(this));
    uint256 totalTokensToSwap = tokensForLiquidity + tokensForRevShare + tokensForTeam;
    bool success;

    if (contractBalance == 0 || totalTokensToSwap == 0) {
      return;
    }

    if (contractBalance > swapTokensAtAmount * 20) {
      contractBalance = swapTokensAtAmount * 20;
    }

    // Halve the amount of liquidity tokens
    uint256 liquidityTokens = (contractBalance * tokensForLiquidity) / totalTokensToSwap / 2;
    uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

    uint256 initialETHBalance = address(this).balance;

    swapTokensForEth(amountToSwapForETH);

    uint256 ethBalance = address(this).balance.sub(initialETHBalance);

    uint256 ethForRevShare = ethBalance.mul(tokensForRevShare).div(
      totalTokensToSwap - (tokensForLiquidity / 2)
    );

    uint256 ethForTeam = ethBalance.mul(tokensForTeam).div(
      totalTokensToSwap - (tokensForLiquidity / 2)
    );

    uint256 ethForLiquidity = ethBalance - ethForRevShare - ethForTeam;

    tokensForLiquidity = 0;
    tokensForRevShare = 0;
    tokensForTeam = 0;

    (success, ) = address(teamAddress).call{ value: ethForTeam }('');

    if (liquidityTokens > 0 && ethForLiquidity > 0) {
      addLiquidity(liquidityTokens, ethForLiquidity);
      emit SwapToLP(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
    }

    (success, ) = address(revShareAddress).call{ value: address(this).balance }('');
  }

  // --- emergency withdraw
  function withdrawStuckToken(address _token) external onlyOwner {
    require(_token != address(0), '_token address cannot be 0');
    uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(teamAddress, _contractBalance);
  }

// --- emergency withdraw
  function withdrawStuckEth() external onlyOwner {
    (bool success, ) = teamAddress.call{ value: address(this).balance }('');
    require(success, 'Failed to withdraw ETH');
  }

  function isBanned(address account) external view returns (bool) {
    return banned[account];
  }

  function renounceBanCapability() external onlyOwner {
    banCapabilityRenounced = true;
  }

  // --- banning methods to prevent abuses and bots
  function ban(address _address) external onlyOwner {
    require(!banCapabilityRenounced, 'Team has revoked ban rights');
    require(
      _address != address(uniswapV2Pair) &&
        _address != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), // UniV2 router
      'Cannot ban Uniswap'
    );

    banned[_address] = true;
  }

  function unban(address _addr) external onlyOwner {
    banned[_addr] = false;
  }
}