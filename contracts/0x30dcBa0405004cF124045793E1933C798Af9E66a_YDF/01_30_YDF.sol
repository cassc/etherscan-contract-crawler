/******************************************************************************************************
Yieldification (YDF)

Website: https://yieldification.com
Twitter: https://twitter.com/yieldification
Telegram: https://t.me/yieldification
******************************************************************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './interfaces/IYDF.sol';
import './sYDF.sol';
import './slYDF.sol';
import './YDFVester.sol';
import './StakeRewards.sol';

contract YDF is IYDF, ERC20, Ownable {
  uint256 private constant EARLY_SELL_EXPIRATION = 90 days;
  uint256 private constant SET_AND_LOCK_TAXES = 30 days;
  uint256 private constant LAUNCH_MAX_TXN_PERIOD = 30 minutes;

  // at launch, a higher marketing+rewards tax will support initial capital generated
  // for hiring and paying for an initial marketing blitz. After 30 days the contract
  // reduces the marketing percent to 1%, which it can no longer be adjusted.
  uint256 public taxMarketingPerc = 300; // 3%
  uint256 public taxRewardsPerc = 200; // 2%
  uint256 public taxEarlyPerc = 1000; // 10%

  sYDF private _stakedYDF;
  slYDF private _stakedYDFLP;
  YDFVester private _vester;
  StakeRewards private _rewards;

  address public treasury;
  uint256 public launchBlock;
  uint256 public launchTime;

  mapping(address => bool) public isTaxExcluded;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  mapping(address => bool) public mmPairs; // market making pairs

  // the following are used to track logic for the time-decaying sell tax.
  // buyTracker and sellTracker will be appended to each buy/sell respectively,
  // where as lastBuyTimestamp is reset each buy. As long as the buyTracker
  // exceeds the sellTracker, the decaying sell tax will reduce continuously
  // against the lastBuyTimestamp, but at the moment the user sells and
  // the sellTracker exceeds the buyTracker, all are reset which will mean
  // the sell tax will be no longer decaying for this wallet until the wallet
  // buys again and everything starts from scratch again.
  //
  // IMPORTANT: the time-decay tax is measured against lastBuyTimestamp, meaning
  // each time a wallet buys, their time decay is reset back to the beginning.
  mapping(address => uint256) public buyTracker;
  mapping(address => uint256) public lastBuyTimestamp;
  mapping(address => uint256) public sellTracker;

  mapping(address => bool) private _isBot;

  bool private _swapping = false;
  bool private _swapEnabled = true;

  modifier onlyStake() {
    require(
      address(_stakedYDF) == _msgSender() ||
        address(_stakedYDFLP) == _msgSender(),
      'not a staking contract'
    );
    _;
  }

  modifier onlyVest() {
    require(address(_vester) == _msgSender(), 'not vesting contract');
    _;
  }

  modifier swapLock() {
    _swapping = true;
    _;
    _swapping = false;
  }

  event SetMarketMakingPair(address indexed pair, bool isPair);
  event SetTreasury(address indexed newTreasury);
  event StakeMintToVester(uint256 amount);
  event Burn(address indexed user, uint256 amount);
  event ResetBuySellMetadata(address indexed user);
  event SetTaxExclusion(address indexed user, bool isExcluded);

  constructor() ERC20('Yieldification', 'YDF') {
    _mint(msg.sender, 696_900_000 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    _vester = new YDFVester(address(this));
    _rewards = new StakeRewards(address(this), address(_uniswapV2Router));

    _stakedYDF = new sYDF(
      address(this),
      address(_vester),
      address(_rewards),
      'https://api.yieldification.com/sydf/metadata/'
    );
    _stakedYDF.setPaymentAddress(msg.sender);
    _stakedYDF.setRoyaltyAddress(msg.sender);
    _stakedYDF.transferOwnership(msg.sender);

    _stakedYDFLP = new slYDF(
      uniswapV2Pair,
      address(_uniswapV2Router),
      address(this),
      address(_vester),
      address(_rewards),
      'https://api.yieldification.com/slydf/metadata/'
    );
    _stakedYDFLP.setPaymentAddress(msg.sender);
    _stakedYDFLP.setRoyaltyAddress(msg.sender);
    _stakedYDFLP.transferOwnership(msg.sender);

    _vester.addStakingContract(address(_stakedYDF));
    _vester.addStakingContract(address(_stakedYDFLP));
    _vester.transferOwnership(msg.sender);

    _rewards.setsYDF(address(_stakedYDF));
    _rewards.setslYDF(address(_stakedYDFLP));
    _rewards.transferOwnership(msg.sender);

    mmPairs[uniswapV2Pair] = true;
    uniswapV2Router = _uniswapV2Router;
    treasury = msg.sender;

    isTaxExcluded[address(this)] = true;
    isTaxExcluded[address(_stakedYDFLP)] = true; // allow zapping without taxes
    isTaxExcluded[msg.sender] = true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isBuy = mmPairs[sender] && recipient != address(uniswapV2Router);
    bool _isSell = mmPairs[recipient];

    if (_isBuy) {
      require(launchBlock > 0, 'not launched yet');

      buyTracker[recipient] += amount;
      lastBuyTimestamp[recipient] = block.timestamp;
      if (block.number <= launchBlock + 2) {
        _isBot[recipient] = true;
      } else if (block.timestamp < launchTime + LAUNCH_MAX_TXN_PERIOD) {
        require(
          balanceOf(recipient) + amount <= (totalSupply() * 1) / 100,
          'at launch max wallet is up to 1% supply'
        );
      }
    } else {
      require(!_isBot[recipient], 'sorry bot');
      require(!_isBot[sender], 'sorry bot');
      require(!_isBot[_msgSender()], 'sorry bot');
    }

    uint256 contractBalance = balanceOf(address(this));
    uint256 _swapAmount = (balanceOf(uniswapV2Pair) * 5) / 1000; // 0.5% pair balance
    bool _overMinimum = contractBalance >= _swapAmount && _swapAmount > 0;
    if (!_swapping && _swapEnabled && _overMinimum && sender != uniswapV2Pair) {
      _swapForETH(_swapAmount);
    }

    uint256 tax = 0;
    if (_isSell && !(isTaxExcluded[sender] || isTaxExcluded[recipient])) {
      // at the expiration date we will reset taxes which will
      // set them forever in the contract to no longer be changed
      if (
        block.timestamp > launchTime + SET_AND_LOCK_TAXES &&
        taxMarketingPerc > 100
      ) {
        taxMarketingPerc = 100; // 1%
        taxRewardsPerc = 100; // 1%
        taxEarlyPerc = 1300; // 13%
      }

      uint256 _taxEarlyPerc = getSellEarlyTax(sender, amount, taxEarlyPerc);
      uint256 _totalTax = taxMarketingPerc + taxRewardsPerc + _taxEarlyPerc;
      tax = (amount * _totalTax) / 10000;
      if (tax > 0) {
        uint256 _taxAmountETH = (tax * (taxMarketingPerc + taxRewardsPerc)) /
          _totalTax;
        super._transfer(sender, address(this), _taxAmountETH);
        if (_taxEarlyPerc > 0) {
          _burnWithEvent(sender, tax - _taxAmountETH);
        }
      }
      sellTracker[sender] += amount;
    }

    super._transfer(sender, recipient, amount - tax);

    // if the sell tracker equals or exceeds the amount of tokens bought,
    // reset all variables here which resets the time-decaying sell tax logic.
    if (sellTracker[sender] >= buyTracker[sender]) {
      _resetBuySellMetadata(sender);
    }
    // handles transferring to a fresh wallet or wallet that hasn't bought YDF before
    if (lastBuyTimestamp[recipient] == 0) {
      _resetBuySellMetadata(recipient);
    }
  }

  function _swapForETH(uint256 _amountToSwap) private swapLock {
    uint256 _balBefore = address(this).balance;

    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), _amountToSwap);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _amountToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 _balToProcess = address(this).balance - _balBefore;
    if (_balToProcess > 0) {
      uint256 _totalTaxETH = taxMarketingPerc + taxRewardsPerc;

      // send marketing ETH
      uint256 _marketingETH = (_balToProcess * taxMarketingPerc) / _totalTaxETH;
      address _treasury = treasury == address(0) ? owner() : treasury;
      if (_marketingETH > 0) {
        payable(_treasury).call{ value: _marketingETH }('');
      }

      // deposit rewards into rewards pool
      uint256 _rewardsETH = _balToProcess - _marketingETH;
      if (_rewardsETH > 0) {
        if (_rewards.totalSharesDeposited() > 0) {
          _rewards.depositRewards{ value: _rewardsETH }();
        } else {
          payable(_treasury).call{ value: _rewardsETH }('');
        }
      }
    }
  }

  function getSellEarlyTax(
    address _seller,
    uint256 _sellAmount,
    uint256 _tax
  ) public view returns (uint256) {
    if (lastBuyTimestamp[_seller] == 0) {
      return _tax;
    }

    if (sellTracker[_seller] + _sellAmount > buyTracker[_seller]) {
      return _tax;
    }

    if (block.timestamp > getSellEarlyExpiration(_seller)) {
      return 0;
    }
    uint256 _secondsAfterBuy = block.timestamp - lastBuyTimestamp[_seller];
    return
      (_tax * (EARLY_SELL_EXPIRATION - _secondsAfterBuy)) /
      EARLY_SELL_EXPIRATION;
  }

  function getSellEarlyExpiration(address _seller)
    public
    view
    returns (uint256)
  {
    return
      lastBuyTimestamp[_seller] == 0
        ? 0
        : lastBuyTimestamp[_seller] + EARLY_SELL_EXPIRATION;
  }

  function getStakedYDF() external view returns (address) {
    return address(_stakedYDF);
  }

  function getStakedYDFLP() external view returns (address) {
    return address(_stakedYDFLP);
  }

  function getVester() external view returns (address) {
    return address(_vester);
  }

  function getRewards() external view returns (address) {
    return address(_rewards);
  }

  function addToBuyTracker(address _user, uint256 _amount) external onlyVest {
    buyTracker[_user] += _amount;
    // if this user hasn't bought before, but is vesting from unstaking an
    // acquired stake NFT, go ahead and set their buy timetstamp here from now
    if (lastBuyTimestamp[_user] == 0) {
      lastBuyTimestamp[_user] = block.timestamp;
    }
  }

  function resetBuySellMetadata() external {
    _resetBuySellMetadata(msg.sender);
    emit ResetBuySellMetadata(msg.sender);
  }

  function _resetBuySellMetadata(address _user) internal {
    buyTracker[_user] = balanceOf(_user);
    lastBuyTimestamp[_user] = block.timestamp;
    sellTracker[_user] = 0;
  }

  function stakeMintToVester(uint256 _amount) external override onlyStake {
    _mint(address(_vester), _amount);
    emit StakeMintToVester(_amount);
  }

  function burn(uint256 _amount) external {
    _burnWithEvent(msg.sender, _amount);
  }

  function _burnWithEvent(address _user, uint256 _amount) internal {
    _burn(_user, _amount);
    emit Burn(_user, _amount);
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    isTaxExcluded[_wallet] = _isExcluded;
    emit SetTaxExclusion(_wallet, _isExcluded);
  }

  function setMarketMakingPair(address _addy, bool _isPair) external onlyOwner {
    require(_addy != uniswapV2Pair, 'cannot change state of built-in pair');
    mmPairs[_addy] = _isPair;
    emit SetMarketMakingPair(_addy, _isPair);
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit SetTreasury(_treasury);
  }

  function startTrading() external onlyOwner {
    require(launchBlock == 0, 'already launched');
    launchBlock = block.number;
    launchTime = block.timestamp;
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  receive() external payable {}
}