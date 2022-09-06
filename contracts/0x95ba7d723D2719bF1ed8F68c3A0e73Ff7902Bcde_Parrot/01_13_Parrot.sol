// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './ParrotRewards.sol';

contract Parrot is ERC20, Ownable {
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  address public developmentWallet;
  address public treasuryWallet;
  address public liquidityWallet;

  uint256 public buyDevelopmentFee = 20; // 2%
  uint256 public buyTreasuryFee = 20; // 2%
  uint256 public buyLiquidityFee = 20; // 2%
  uint256 public buyTotalFees =
    buyDevelopmentFee + buyTreasuryFee + buyLiquidityFee;

  uint256 public sellDevelopmentFee = 20; // 2%
  uint256 public sellTreasuryFee = 20; // 2%
  uint256 public sellLiquidityFee = 20; // 2%
  uint256 public sellTotalFees =
    sellDevelopmentFee + sellTreasuryFee + sellLiquidityFee;

  uint256 public tokensForDevelopment;
  uint256 public tokensForTreasury;
  uint256 public tokensForLiquidity;

  ParrotRewards private _rewards;
  mapping(address => bool) private _isTaxExcluded;
  bool private _taxesOff;

  uint256 public maxTxnAmount;
  mapping(address => bool) public isExcludedMaxTxnAmount;
  uint256 public maxWallet;
  mapping(address => bool) public isExcludedMaxWallet;

  uint256 public liquifyRate = 10; // 1% of LP balance

  address public uniswapV2Pair;
  IUniswapV2Router02 public uniswapV2Router;
  mapping(address => bool) public marketMakingPairs;

  mapping(address => bool) private _isBlacklisted;

  bool private _swapEnabled = true;
  bool private _swapping = false;
  modifier lockSwap() {
    _swapping = true;
    _;
    _swapping = false;
  }

  constructor() ERC20('Parrot', 'PRT') {
    _mint(msg.sender, 1_000_000_000 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());
    marketMakingPairs[_uniswapV2Pair] = true;
    uniswapV2Pair = _uniswapV2Pair;
    uniswapV2Router = _uniswapV2Router;

    maxTxnAmount = (totalSupply() * 1) / 100; // 1% supply
    maxWallet = (totalSupply() * 1) / 100; // 1% supply

    _rewards = new ParrotRewards(address(this));
    _rewards.transferOwnership(msg.sender);
    _isTaxExcluded[address(this)] = true;
    _isTaxExcluded[msg.sender] = true;
    isExcludedMaxTxnAmount[address(this)] = true;
    isExcludedMaxTxnAmount[msg.sender] = true;
    isExcludedMaxWallet[address(this)] = true;
    isExcludedMaxWallet[msg.sender] = true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isBuy = marketMakingPairs[sender] &&
      recipient != address(uniswapV2Router);
    bool _isSell = marketMakingPairs[recipient];
    bool _isSwap = _isBuy || _isSell;
    address _marketMakingPair;

    if (!_isBuy) {
      require(!_isBlacklisted[recipient], 'blacklisted wallet');
      require(!_isBlacklisted[sender], 'blacklisted wallet');
      require(!_isBlacklisted[_msgSender()], 'blacklisted wallet');
    }

    if (_isSwap) {
      if (_isBuy) {
        // buy
        _marketMakingPair = sender;

        if (!isExcludedMaxTxnAmount[recipient]) {
          require(
            amount <= maxTxnAmount,
            'cannot swap more than max transaction amount'
          );
        }
      } else {
        // sell
        _marketMakingPair = recipient;

        if (!isExcludedMaxTxnAmount[sender]) {
          require(
            amount <= maxTxnAmount,
            'cannot swap more than max transaction amount'
          );
        }
      }
    }

    // enforce on buys and wallet/wallet transfers only
    if (!_isSell && !isExcludedMaxWallet[recipient]) {
      require(
        amount + balanceOf(recipient) <= maxWallet,
        'max wallet exceeded'
      );
    }

    uint256 _minSwap = totalSupply();
    if (_marketMakingPair != address(0)) {
      _minSwap =
        (balanceOf(_marketMakingPair) * liquifyRate) /
        PERCENT_DENOMENATOR;
      _minSwap = _minSwap == 0 ? totalSupply() : _minSwap;
    }
    bool _overMin = tokensForDevelopment +
      tokensForTreasury +
      tokensForLiquidity >=
      _minSwap;
    if (_swapEnabled && !_swapping && _overMin && sender != _marketMakingPair) {
      _swap(_minSwap);
    }

    uint256 tax = 0;
    if (
      _isSwap &&
      !_taxesOff &&
      !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
    ) {
      if (_isBuy) {
        tax = (amount * buyTotalFees) / PERCENT_DENOMENATOR;
        tokensForDevelopment += (tax * buyDevelopmentFee) / buyTotalFees;
        tokensForTreasury += (tax * buyTreasuryFee) / buyTotalFees;
        tokensForLiquidity += (tax * buyLiquidityFee) / buyTotalFees;
      } else {
        // sell
        tax = (amount * sellTotalFees) / PERCENT_DENOMENATOR;
        tokensForDevelopment += (tax * sellDevelopmentFee) / sellTotalFees;
        tokensForTreasury += (tax * sellTreasuryFee) / sellTotalFees;
        tokensForLiquidity += (tax * sellLiquidityFee) / sellTotalFees;
      }
      if (tax > 0) {
        super._transfer(sender, address(this), tax);
      }
    }

    super._transfer(sender, recipient, amount - tax);

    _trueUpTaxTokens();
  }

  function _swap(uint256 _amountToSwap) private lockSwap {
    uint256 _tokensForDevelopment = tokensForDevelopment;
    uint256 _tokensForTreasury = tokensForTreasury;
    uint256 _tokensForLiquidity = tokensForLiquidity;

    // the max amount we want to swap is _amountToSwap, so make sure if
    // the amount of tokens that are available to swap is more than that,
    // that we adjust the tokens to swap to be max that amount.
    if (
      _tokensForDevelopment + _tokensForTreasury + _tokensForLiquidity >
      _amountToSwap
    ) {
      _tokensForLiquidity = _tokensForLiquidity > _amountToSwap
        ? _amountToSwap
        : _tokensForLiquidity;
      uint256 _remaining = _amountToSwap - _tokensForLiquidity;
      _tokensForTreasury =
        (_remaining * buyTreasuryFee) /
        (buyTreasuryFee + buyDevelopmentFee);
      _tokensForDevelopment = _remaining - _tokensForTreasury;
    }

    uint256 _balBefore = address(this).balance;
    uint256 _liquidityTokens = _tokensForLiquidity / 2;
    uint256 _finalAmountToSwap = _tokensForDevelopment +
      _tokensForTreasury +
      _liquidityTokens;

    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), _finalAmountToSwap);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _finalAmountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 balToProcess = address(this).balance - _balBefore;
    if (balToProcess > 0) {
      uint256 _treasuryETH = (balToProcess * _tokensForTreasury) /
        _finalAmountToSwap;
      uint256 _developmentETH = (balToProcess * _tokensForDevelopment) /
        _finalAmountToSwap;
      uint256 _liquidityETH = balToProcess - _treasuryETH - _developmentETH;
      _processFees(
        _developmentETH,
        _treasuryETH,
        _liquidityETH,
        _liquidityTokens
      );
    }

    tokensForDevelopment -= _tokensForDevelopment;
    tokensForTreasury -= _tokensForTreasury;
    tokensForLiquidity -= _tokensForLiquidity;
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      liquidityWallet == address(0) ? owner() : liquidityWallet,
      block.timestamp
    );
  }

  function _processFees(
    uint256 _developmentETH,
    uint256 _treasuryETH,
    uint256 _liquidityETH,
    uint256 _liquidityTokens
  ) private {
    if (_developmentETH > 0) {
      address _developmentWallet = developmentWallet == address(0)
        ? owner()
        : developmentWallet;
      payable(_developmentWallet).call{ value: _developmentETH }('');
    }

    if (_treasuryETH > 0) {
      address _treasuryWallet = treasuryWallet == address(0)
        ? owner()
        : treasuryWallet;
      payable(_treasuryWallet).call{ value: _treasuryETH }('');
    }

    if (_liquidityETH > 0 && _liquidityTokens > 0) {
      _addLp(_liquidityTokens, _liquidityETH);
    }
  }

  function _trueUpTaxTokens() internal {
    uint256 _latestBalance = balanceOf(address(this));
    uint256 _latestDesiredBal = tokensForDevelopment +
      tokensForTreasury +
      tokensForLiquidity;
    if (_latestDesiredBal != _latestBalance) {
      if (_latestDesiredBal > _latestBalance) {
        bool _areExcessMoreThanBal = tokensForDevelopment + tokensForTreasury >
          _latestBalance;
        tokensForTreasury = _areExcessMoreThanBal ? 0 : tokensForTreasury;
        tokensForDevelopment = _areExcessMoreThanBal ? 0 : tokensForDevelopment;
      }
      tokensForLiquidity =
        _latestBalance -
        tokensForTreasury -
        tokensForDevelopment;
    }
  }

  function rewardsContract() external view returns (address) {
    return address(_rewards);
  }

  function isBlacklisted(address wallet) external view returns (bool) {
    return _isBlacklisted[wallet];
  }

  function blacklistWallet(address wallet) external onlyOwner {
    require(
      wallet != address(uniswapV2Router),
      'cannot not blacklist dex router'
    );
    require(!_isBlacklisted[wallet], 'wallet is already blacklisted');
    _isBlacklisted[wallet] = true;
  }

  function forgiveBlacklistedWallet(address wallet) external onlyOwner {
    require(_isBlacklisted[wallet], 'wallet is not blacklisted');
    _isBlacklisted[wallet] = false;
  }

  function setBuyTaxes(
    uint256 _developmentFee,
    uint256 _treasuryFee,
    uint256 _liquidityFee
  ) external onlyOwner {
    buyDevelopmentFee = _developmentFee;
    buyTreasuryFee = _treasuryFee;
    buyLiquidityFee = _liquidityFee;
    buyTotalFees = buyDevelopmentFee + buyTreasuryFee + buyLiquidityFee;
    require(
      buyTotalFees <= (PERCENT_DENOMENATOR * 15) / 100,
      'tax cannot be more than 15%'
    );
  }

  function setSellTaxes(
    uint256 _developmentFee,
    uint256 _treasuryFee,
    uint256 _liquidityFee
  ) external onlyOwner {
    sellDevelopmentFee = _developmentFee;
    sellTreasuryFee = _treasuryFee;
    sellLiquidityFee = _liquidityFee;
    sellTotalFees = sellDevelopmentFee + sellTreasuryFee + sellLiquidityFee;
    require(
      sellTotalFees <= (PERCENT_DENOMENATOR * 15) / 100,
      'tax cannot be more than 15%'
    );
  }

  function setMarketMakingPair(address _addy, bool _isPair) external onlyOwner {
    marketMakingPairs[_addy] = _isPair;
  }

  function setDevelopmentWallet(address _wallet) external onlyOwner {
    developmentWallet = _wallet;
  }

  function setTreasuryWallet(address _wallet) external onlyOwner {
    treasuryWallet = _wallet;
  }

  function setLiquidityWallet(address _wallet) external onlyOwner {
    liquidityWallet = _wallet;
  }

  function setMaxTxnAmount(uint256 _numTokens) external onlyOwner {
    require(
      _numTokens >= (totalSupply() * 1) / 1000,
      'must be more than 0.1% supply'
    );
    maxTxnAmount = _numTokens;
  }

  function setMaxWallet(uint256 _numTokens) external onlyOwner {
    require(
      _numTokens >= (totalSupply() * 5) / 1000,
      'must be more than 0.5% supply'
    );
    maxWallet = _numTokens;
  }

  function setLiquifyRate(uint256 _rate) external onlyOwner {
    require(_rate <= PERCENT_DENOMENATOR / 10, 'must be less than 10%');
    liquifyRate = _rate;
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    _isTaxExcluded[_wallet] = _isExcluded;
  }

  function setIsExcludeFromMaxTxnAmount(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    isExcludedMaxTxnAmount[_wallet] = _isExcluded;
  }

  function setIsExcludeFromMaxWallet(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    isExcludedMaxWallet[_wallet] = _isExcluded;
  }

  function setTaxesOff(bool _areOff) external onlyOwner {
    _taxesOff = _areOff;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    require(_tokenAddy != address(this), 'cannot withdraw this token');
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  receive() external payable {}
}