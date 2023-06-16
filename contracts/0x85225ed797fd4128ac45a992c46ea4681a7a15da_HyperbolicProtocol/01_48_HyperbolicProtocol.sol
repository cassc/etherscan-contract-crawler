// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import './LendingRewards.sol';
import './RewardsLocker.sol';
import './UniswapV3FeeERC20.sol';
import './interfaces/IHyperbolicProtocol.sol';
import './interfaces/ILendingPool.sol';
import './interfaces/ITwapUtils.sol';
import './interfaces/IWETH.sol';

contract HyperbolicProtocol is IHyperbolicProtocol, UniswapV3FeeERC20 {
  uint32 constant DENOMENATOR = 10000;

  ILendingPool public lendingPool;
  LendingRewards public lendingRewards;
  RewardsLocker public rewardsLocker;
  ITwapUtils public twapUtils;

  uint256 public launchTime;

  uint32 public override poolToMarketCapTarget = DENOMENATOR; // 100%
  bool public taxesEnabled = true;
  bool public taxesOnTransfers;
  bool public taxesOnBuys = true;
  bool public taxesOnSells;
  uint32 public minTax;
  uint32 public maxTax = (DENOMENATOR * 8) / 100; // 8%
  uint32 public lpTax = (DENOMENATOR * 25) / 100;
  uint256 public swapAtAmount;
  bool public swapEnabled = true;

  mapping(address => bool) public amms; // AMM == Automated Market Maker
  mapping(address => bool) public isBot;
  mapping(address => bool) public rewardsExcluded;

  bool _swapping;
  modifier lockSwap() {
    _swapping = true;
    _;
    _swapping = false;
  }

  event Burn(address wallet, uint256 amount);

  constructor(
    ITwapUtils _twapUtils,
    INonfungiblePositionManager _manager,
    ISwapRouter _swapRouter,
    address _factory,
    address _WETH9
  )
    UniswapV3FeeERC20(
      'Hyperbolic Protocol',
      'HYPE',
      _manager,
      _swapRouter,
      _factory,
      _WETH9
    )
  {
    twapUtils = _twapUtils;
    lendingRewards = new LendingRewards(address(this));
    rewardsLocker = new RewardsLocker(lendingRewards);
    rewardsLocker.transferOwnership(_msgSender());

    rewardsExcluded[address(this)] = true;

    uint256 _totalSuppIncDecimals = 100_000_000 * 10 ** decimals();
    uint256 _lockerTokens = (_totalSuppIncDecimals * 10) / 100; // 10% to locker forever
    uint256 _disTokens = _totalSuppIncDecimals - _lockerTokens;
    _mint(address(rewardsLocker), _lockerTokens);
    _mint(owner(), _disTokens);
    swapAtAmount = (_totalSuppIncDecimals * 2) / 1000; // 0.2% supply
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isBuy = amms[sender] && recipient != address(swapRouter);
    bool _isSell = amms[recipient];
    uint256 _tax;

    if (_isBuy || _isSell) {
      require(launchTime > 0, 'TRANSFER: not launched');
    }

    if (launchTime > 0) {
      if (_isBuy) {
        if (block.timestamp <= launchTime + 10 seconds) {
          isBot[recipient] = true;
        } else if (block.timestamp <= launchTime + 30 minutes) {
          uint256 _launchMax = balanceOf(recipient) + amount;
          require(_launchMax <= totalSupply() / 100, 'max 1% at launch');
        }
      } else if (block.timestamp > launchTime + 10 seconds) {
        require(!isBot[recipient], 'TRANSFER: bot0');
        require(!isBot[sender], 'TRANSFER: bot1');
        require(!isBot[_msgSender()], 'TRANSFER: bot2');
      }

      if (
        !_swapping &&
        swapEnabled &&
        liquidityPosInitialized &&
        swapAtAmount > 0 &&
        balanceOf(address(this)) >= swapAtAmount
      ) {
        _swapForETHAndProcess();
      }

      if (taxesEnabled && _shouldBeTaxed(_isBuy, _isSell)) {
        _tax = calculateTaxFromAmount(amount);
        if (_tax > 0) {
          super._transfer(sender, address(this), _tax);
          _afterTokenTransfer(sender, address(this), _tax);
        }
      }
    }

    super._transfer(sender, recipient, amount - _tax);
    _afterTokenTransfer(sender, recipient, amount - _tax);
  }

  // NOTE: need this to execute _afterTokenTransfer callback (not present in openzeppelin 3.4.2)
  function _mint(address account, uint256 amount) internal override {
    super._mint(account, amount);
    _afterTokenTransfer(address(0), account, amount);
  }

  // NOTE: need this to execute _afterTokenTransfer callback (not present in openzeppelin 3.4.2)
  function _burn(address account, uint256 amount) internal override {
    super._burn(account, amount);
    _afterTokenTransfer(account, address(0), amount);
  }

  function burn(uint256 _amount) external {
    _burn(_msgSender(), _amount);
    emit Burn(_msgSender(), _amount);
  }

  function calculateTaxFromAmount(
    uint256 _amount
  ) public view returns (uint256) {
    (uint256 _poolBalETH, uint256 _mcETH) = poolBalToMarketCapRatio();
    uint256 _targetPoolBal = (_mcETH * poolToMarketCapTarget) / DENOMENATOR;
    if (_poolBalETH < _targetPoolBal) {
      uint256 _taxLessMax = ((maxTax - minTax) * _poolBalETH) / _targetPoolBal;
      return (_amount * (maxTax - _taxLessMax)) / DENOMENATOR;
    }
    return (_amount * minTax) / DENOMENATOR;
  }

  function poolBalToMarketCapRatio()
    public
    view
    override
    returns (uint256 lendPoolETHBal, uint256 marketCapETH)
  {
    (, , address _pool) = _getPoolInfo(_lpPoolFees[0]);
    if (_pool == address(0)) {
      return (0, 0);
    }
    lendPoolETHBal = address(lendingPool).balance;

    // get token market cap relative to token1 (WETH) and calculate
    // tax based on lending pool balance of ETH (higher bal, lower tax)
    uint160 _sqrtPriceX96 = twapUtils.getSqrtPriceX96FromPoolAndInterval(_pool);
    uint256 _priceX96 = twapUtils.getPriceX96FromSqrtPriceX96(_sqrtPriceX96);
    address _token0 = IUniswapV3Pool(_pool).token0();
    marketCapETH = _token0 == address(this)
      ? (totalSupply() * _priceX96) / FixedPoint96.Q96
      : (totalSupply() * FixedPoint96.Q96) / _priceX96;
  }

  // _fee: 3000 == 0.3%, 10000 == 1%
  // _initialPriceX96 = initialPrice * 2**96
  // initialPrice = token1Reserves / token0Reserves
  function lpCreatePool(
    uint24 _fee,
    uint256 _initialPriceX96,
    uint16 _initPriceObservations
  ) external onlyOwner {
    _createLiquidityPool(
      _fee,
      twapUtils.getSqrtPriceX96FromPriceX96(_initialPriceX96),
      _initPriceObservations
    );
  }

  // _fee: 3000 == 0.3%, 10000 == 1%
  function lpCreatePosition(
    uint24 _fee,
    uint256 _tokensNoDecimals
  ) external payable onlyOwner {
    require(msg.value > 0, 'ADDLP0');

    uint256 _tokens = _tokensNoDecimals * 10 ** decimals();
    super._transfer(_msgSender(), address(this), _tokens);
    address _pool = _createLiquidityPosition(_fee, _tokens, msg.value);
    _setIsRewardsExcluded(_pool, true);
    amms[_pool] = true;
  }

  function launch() external onlyOwner {
    require(launchTime == 0, 'LAUNCH: already launched');
    require(liquidityPosInitialized, 'LAUNCH: exec lpCreatePosition');
    launchTime = block.timestamp;
  }

  function toggleAmm(address _amm) external onlyOwner {
    amms[_amm] = !amms[_amm];
  }

  function forgiveBot(address _bot) external onlyOwner {
    require(isBot[_bot], 'FORGIVE: not a bot');
    isBot[_bot] = false;
  }

  function setIsRewardsExcluded(
    address _wallet,
    bool _isExcluded
  ) external onlyOwner {
    _setIsRewardsExcluded(_wallet, _isExcluded);
  }

  function _setIsRewardsExcluded(address _wallet, bool _isExcluded) internal {
    require(rewardsExcluded[_wallet] != _isExcluded, 'SETEXCL');
    rewardsExcluded[_wallet] = _isExcluded;

    uint256 _walletBal = balanceOf(_wallet);
    if (_walletBal > 0) {
      bool _removeRewards = false;
      if (_isExcluded) {
        _removeRewards = true;
      }
      lendingRewards.setShare(_wallet, _walletBal, _removeRewards);
    }
  }

  function setSwapAtAmount(uint256 _amount) external onlyOwner {
    require(_amount <= (totalSupply() * 2) / 100, 'SETSWAPAM: lte 2%');
    swapAtAmount = _amount;
  }

  function setSwapEnabled(bool _isEnabled) external onlyOwner {
    require(swapEnabled != _isEnabled, 'SETSWAPEN: must toggle');
    swapEnabled = _isEnabled;
  }

  function setPoolToMarketCapTarget(uint32 _target) external onlyOwner {
    require(_target <= DENOMENATOR, 'TARGET: lte 100%');
    poolToMarketCapTarget = _target;
  }

  function setTaxesEnabled(bool _enabled) external onlyOwner {
    require(taxesEnabled != _enabled, 'TAXESENABLED: must toggle');
    taxesEnabled = _enabled;
  }

  function setMinTax(uint32 _tax) external onlyOwner {
    require(_tax <= (DENOMENATOR * 20) / 100, 'SETMINTAX: lte 20%');
    minTax = _tax;
  }

  function setMaxTax(uint32 _tax) external onlyOwner {
    require(_tax <= (DENOMENATOR * 20) / 100, 'SETMAXTAX: lte 20%');
    maxTax = _tax;
  }

  function setLpTax(uint32 _tax) external onlyOwner {
    require(_tax <= DENOMENATOR, 'SETLPTAX: lte 100%');
    lpTax = _tax;
  }

  function setTaxOnAction(
    bool _onBuy,
    bool _onSell,
    bool _onTransfer
  ) external onlyOwner {
    taxesOnBuys = _onBuy;
    taxesOnSells = _onSell;
    taxesOnTransfers = _onTransfer;
  }

  function setLendingPool(ILendingPool _pool) external onlyOwner {
    lendingPool = _pool;
  }

  function manualSwap() external onlyOwner {
    require(balanceOf(address(this)) >= swapAtAmount, 'SWAP: not enough');
    _swapForETHAndProcess();
  }

  function _swapForETHAndProcess() internal lockSwap {
    uint256 _lpTokens = (swapAtAmount * lpTax) / DENOMENATOR / 2;
    uint256 _ethTokens = swapAtAmount - _lpTokens;
    (address _pool, ) = _swapTokensForETH(_ethTokens);

    uint256 _lpETH = (address(this).balance * lpTax) / DENOMENATOR;
    uint256 _lendingPoolETH = address(this).balance - _lpETH;

    if (_lendingPoolETH > 0) {
      address payable _payablePool = payable(address(lendingPool));
      (bool success, ) = _payablePool.call{ value: _lendingPoolETH }('');
      require(success, 'TRANSFER: ETH not sent to pool');
    }

    if (_pool != address(0) && _lpETH > 0) {
      _addToLiquidityPosition(_pool, _lpTokens, _lpETH);
    }
  }

  function _canReceiveRewards(address _wallet) internal view returns (bool) {
    return _wallet != address(0) && !rewardsExcluded[_wallet] && !amms[_wallet];
  }

  function _shouldBeTaxed(
    bool _isBuy,
    bool _isSell
  ) internal view returns (bool) {
    return
      (taxesOnTransfers && !_isBuy && !_isSell) ||
      (taxesOnBuys && _isBuy) ||
      (taxesOnSells && _isSell);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual {
    if (_canReceiveRewards(_from)) {
      lendingRewards.setShare(_from, _amount, true);
    }
    if (_canReceiveRewards(_to)) {
      lendingRewards.setShare(_to, _amount, false);
    }
  }
}