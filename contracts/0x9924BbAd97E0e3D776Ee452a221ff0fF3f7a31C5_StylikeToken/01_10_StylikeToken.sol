// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './access/Ownable.sol';
import './token/ERC20/ERC20.sol';
import './token/ERC20/extensions/ERC20Burnable.sol';

import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Router02.sol';

contract StylikeToken is ERC20, ERC20Burnable, Ownable {
  IUniswapV2Router02 public uniswapV2Router;
  IUniswapV2Router02 public dexRouter;
  address public uniswapV2Pair;

  address operationsAddress;
  address bridge;

  uint256 public constant FEE_DENOMINATOR = 10000;

  uint256 tokenSupply = 98_963_657 * 1e18;

  uint256 public maxBuyAmount;
  uint256 public maxSellAmount;

  uint256 public buyTotalFees;
  uint256 public buyOperationsFee;
  uint256 public buyLiquidityFee;

  uint256 public sellTotalFees;
  uint256 public sellOperationsFee;
  uint256 public sellLiquidityFee;

  uint256 public tokensForOperations;
  uint256 public tokensForLiquidity;

  bool private _swapping;

  bool public swapEnabled = true;
  bool public tradingActive = false;
  bool public limitsInEffect = true;

  uint256 public swapTokensAtAmount;

  mapping(address => bool) private _isExcludedFromFees;
  mapping(address => bool) public isExcludedMaxTransactionAmount;
  mapping(address => bool) public automatedMarketMakerPairs;

  event ExcludeFromFees(address indexed account, bool isExcluded);
  event IncludedInFee(address indexed account);
  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
  event MaxTransactionExclusion(address _address, bool excluded);
  event UpdatedMaxSellAmount(uint256 newAmount);
  event UpdatedMaxBuyAmount(uint256 newAmount);
  event OwnerForcedSwapBack(uint256 timestamp);
  event UpdateSellFees(uint256 sellOperationsFee, uint256 sellLiquidityFee);
  event UpdateBuyFees(uint256 buyOperationsFee, uint256 buyLiquidityFee);
  event EnabledTrading();
  event EnabledSwap();
  event EnabledLimits();
  event RemovedLimits();

  constructor(address _bridge) ERC20('Stylike Governance', 'STYL') {
    dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address _uniswapV2Pair = IUniswapV2Factory(dexRouter.factory()).createPair(
      address(this),
      dexRouter.WETH()
    );

    uniswapV2Router = dexRouter;
    uniswapV2Pair = _uniswapV2Pair;

    _approve(address(this), address(uniswapV2Router), type(uint256).max);

    _excludeFromMaxTransaction(uniswapV2Pair, true);
    _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

    maxBuyAmount = (tokenSupply * 4) / 1000; // 0.4%
    maxSellAmount = (tokenSupply * 4) / 1000; // 0.4%
    swapTokensAtAmount = (tokenSupply * 20) / 1000000; // 0.0020%

    buyOperationsFee = 1000;
    buyLiquidityFee = 0;
    buyTotalFees = buyOperationsFee + buyLiquidityFee;

    sellLiquidityFee = 0;
    sellOperationsFee = 1000;
    sellTotalFees = sellOperationsFee + sellLiquidityFee;

    _excludeFromMaxTransaction(owner(), true);
    _excludeFromMaxTransaction(operationsAddress, true);
    _excludeFromMaxTransaction(address(this), true);
    _excludeFromMaxTransaction(address(0xdead), true);
    _excludeFromMaxTransaction(address(uniswapV2Router), true);

    excludeFromFees(owner(), true);
    excludeFromFees(address(0xdead), true);
    excludeFromFees(operationsAddress, true);
    excludeFromFees(address(this), true);

    bridge = _bridge;
    _mint(owner(), tokenSupply);
  }

  receive() external payable {}

  function mint(address recipient, uint256 amount) public virtual onlyBridge {
    _mint(recipient, amount);
  }

  function burn(uint256 amount)
    public
    virtual
    override(ERC20Burnable)
    onlyBridge
  {
    super.burn(amount);
  }

  function burnFrom(address account, uint256 amount)
    public
    virtual
    override(ERC20Burnable)
    onlyBridge
  {
    super.burnFrom(account, amount);
  }

  function setAutomatedMarketMakerPair(address pair, bool value)
    external
    onlyOwner
  {
    require(
      pair != uniswapV2Pair,
      'The pair cannot be removed from automatedMarketMakerPairs'
    );

    _setAutomatedMarketMakerPair(pair, value);
    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    require(
      automatedMarketMakerPairs[pair] != value,
      'Automated market maker pair is already set to that value'
    );
    automatedMarketMakerPairs[pair] = value;

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
    emit ExcludeFromFees(account, excluded);
  }

  function includeInFee(address account) external onlyOwner {
    _isExcludedFromFees[account] = false;
    emit IncludedInFee(account);
  }

  function isExcludedFromFees(address account) external view returns (bool) {
    return _isExcludedFromFees[account];
  }

  function updateSellFees(uint256 operationsFee, uint256 liquidityFee)
    external
    onlyOwner
  {
    sellOperationsFee = operationsFee;
    sellLiquidityFee = liquidityFee;
    sellTotalFees = sellOperationsFee + sellLiquidityFee;
    require(sellTotalFees <= 2000, 'Must keep fees at 20% or less');
    emit UpdateSellFees(sellOperationsFee, sellLiquidityFee);
  }

  function updateBuyFees(uint256 operationsFee, uint256 liquidityFee)
    external
    onlyOwner
  {
    buyOperationsFee = operationsFee;
    buyLiquidityFee = liquidityFee;
    buyTotalFees = buyOperationsFee + buyLiquidityFee;
    require(buyTotalFees <= 1000, 'Must keep fees at 10% or less');
    emit UpdateBuyFees(buyOperationsFee, buyLiquidityFee);
  }

  function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
    isExcludedMaxTransactionAmount[updAds] = isExcluded;
    emit MaxTransactionExclusion(updAds, isExcluded);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(amount > 0, 'ERC20: transfer must be greater than 0');

    if (!tradingActive) {
      require(
        _isExcludedFromFees[from] || _isExcludedFromFees[to],
        'Trading is not active.'
      );
    }

    if (limitsInEffect) {
      if (
        from != owner() &&
        to != owner() &&
        to != address(0) &&
        to != address(0xdead) &&
        !_isExcludedFromFees[from] &&
        !_isExcludedFromFees[to]
      ) {
        //when buy
        if (
          automatedMarketMakerPairs[from] && !isExcludedMaxTransactionAmount[to]
        ) {
          require(amount <= maxBuyAmount);
        }
        //when sell
        else if (
          automatedMarketMakerPairs[to] && !isExcludedMaxTransactionAmount[from]
        ) {
          require(amount <= maxSellAmount);
        }
      }
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    if (
      canSwap &&
      swapEnabled &&
      !_swapping &&
      !automatedMarketMakerPairs[from] &&
      !_isExcludedFromFees[from] &&
      !_isExcludedFromFees[to]
    ) {
      _swapping = true;
      swapBack();
      _swapping = false;
    }

    bool takeFee = true;

    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
      takeFee = false;
    }

    uint256 fees = 0;

    if (takeFee) {
      // sell
      if (
        automatedMarketMakerPairs[to] &&
        !automatedMarketMakerPairs[from] &&
        sellTotalFees > 0
      ) {
        fees = (amount * sellTotalFees) / FEE_DENOMINATOR;
        tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
        tokensForOperations += (fees * sellOperationsFee) / sellTotalFees;
      }
      // buy
      else if (
        automatedMarketMakerPairs[from] &&
        !automatedMarketMakerPairs[to] &&
        buyTotalFees > 0
      ) {
        fees = (amount * buyTotalFees) / FEE_DENOMINATOR;
        tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
        tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
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
      0, // accept any amount of ETH
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
      address(0xdead),
      block.timestamp
    );
  }

  function changeSwapStatus(bool _enabled) external onlyOwner {
    swapEnabled = _enabled;
  }

  function swapBack() private {
    uint256 contractBalance = balanceOf(address(this));
    uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations;

    if (contractBalance == 0 || totalTokensToSwap == 0) {
      return;
    }

    if (contractBalance > swapTokensAtAmount * 10) {
      contractBalance = swapTokensAtAmount * 10;
    }

    bool success;

    // Halve the amount of liquidity tokens
    uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
      totalTokensToSwap /
      2;

    uint256 initialBalance = address(this).balance;
    swapTokensForEth(contractBalance - liquidityTokens);

    uint256 ethBalance = address(this).balance - initialBalance;
    uint256 ethForLiquidity = ethBalance;

    uint256 ethForOperations = (ethBalance * tokensForOperations) /
      (totalTokensToSwap - (tokensForLiquidity / 2));

    ethForLiquidity -= ethForOperations;

    tokensForLiquidity = 0;
    tokensForOperations = 0;

    if (liquidityTokens > 0 && ethForLiquidity > 0) {
      addLiquidity(liquidityTokens, ethForLiquidity);
    }

    if (ethForOperations > 0) {
      (success, ) = address(operationsAddress).call{ value: ethForOperations }(
        ''
      );
      require(success, 'Failure! fund not sent');
    }
  }

  function enableTrading() external onlyOwner {
    tradingActive = true;
    emit EnabledTrading();
  }

  function enableSwap() external onlyOwner {
    swapEnabled = true;
    emit EnabledSwap();
  }

  function removeLimits() external onlyOwner {
    limitsInEffect = false;
    emit RemovedLimits();
  }

  function enableLimits() external onlyOwner {
    limitsInEffect = true;
    emit EnabledLimits();
  }

  function claimStuckTokens(address token) external onlyOwner {
    require(token != address(this), 'Owner cannot claim native tokens');
    if (token == address(0x0)) {
      payable(msg.sender).transfer(address(this).balance);
      return;
    }
    IERC20 ERC20token = IERC20(token);
    uint256 balance = ERC20token.balanceOf(address(this));
    ERC20token.transfer(msg.sender, balance);
  }

  function setOperationsAddress(address operationsNewAddress)
    external
    onlyOwner
  {
    require(operationsNewAddress != address(0));
    operationsAddress = payable(operationsNewAddress);
  }

  function forceSwapBack() external onlyOwner {
    require(
      balanceOf(address(this)) >= swapTokensAtAmount,
      'Can only swap when token amount is at or higher than restriction'
    );
    _swapping = true;
    swapBack();
    _swapping = false;
    emit OwnerForcedSwapBack(block.timestamp);
  }

  function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
    require(newAmount >= (tokenSupply * 1) / 1000000);
    require(newAmount <= (tokenSupply * 1) / 1000);
    swapTokensAtAmount = newAmount;
  }

  function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
    require(newNum >= ((tokenSupply * 25) / 10000) / (10**decimals()));
    maxBuyAmount = newNum * (10**decimals());
    emit UpdatedMaxBuyAmount(maxBuyAmount);
  }

  function updateMaxSellAmount(uint256 newNum) external onlyOwner {
    require(newNum >= ((tokenSupply * 25) / 10000) / (10**decimals()));
    maxSellAmount = newNum * (10**decimals());
    emit UpdatedMaxSellAmount(maxSellAmount);
  }

  function updateBridgeAddress(address bridgeNewAddress) external onlyOwner {
    require(bridgeNewAddress != address(0));
    bridge = bridgeNewAddress;
  }

  modifier onlyBridge() {
    require(
      msg.sender == bridge,
      'only bridge has access to this token function'
    );
    _;
  }
}