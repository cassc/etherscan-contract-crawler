// SPDX-License-Identifier:MIT

pragma solidity ^0.8.10;

import { ITradingTokenV1 } from "./ITradingTokenV1.sol";
import { IERC20 } from "../library/IERC20.sol";
import { OwnableV2 } from "../Control/OwnableV2.sol";
import { SafeMath } from "../library/SafeMath.sol";
import { FeeCollector } from "../Fees/FeeCollector.sol";
import { IUniswapV2Factory, IUniswapV2Pair, IUniswapV2Router02 } from "../library/Dex.sol";

contract TradingTokenV1 is ITradingTokenV1, IERC20, OwnableV2, FeeCollector {

  using SafeMath for uint256;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
  address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;

  uint _buyDevelopmentTax;
  uint _buyLpTax;
  uint _buyRewardTax;

  uint _sellDevelopmentTax;
  uint _sellLpTax;
  uint _sellRewardTax;

  uint public _totalBuyFee;
  uint public _totalSellFee;
  
  uint feedenominator = 100;

  address public developmentWallet;
  address public lpReceiverWallet;
  address public rewardWallet;

  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) public isExcludedFromFee;
  mapping (address => bool) public isMarketPair;
  mapping (address => bool) public isWalletLimitExempt;
  mapping (address => bool) public isTxLimitExempt;

  uint256 private _totalSupply;

  uint256 public _maxTxAmount;
  uint256 public _maxWallet;

  uint256 public swapThreshold;

  uint256 public launchedAt;
  bool public normalizeTrade;

  bool tradingActive;

  bool public swapEnabled = false;
  bool public swapByLimit = false;
  bool public enableTxLimit = false;
  bool public checkWalletLimit = false;

  IUniswapV2Router02 public dexRouter;
  address public dexPair;

  bool inSwap;

  modifier onlyGuard() {
    require(msg.sender == lpReceiverWallet,"Invalid Caller");
    _;
  }

  modifier swapping() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor(
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    address owner_,
    uint256[] memory tokenData
  ) OwnableV2(owner_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    _totalSupply = totalSupply_ * 10**_decimals;

    _buyDevelopmentTax = tokenData[3];
    _buyLpTax = tokenData[4];
    _buyRewardTax = tokenData[5];
    _sellDevelopmentTax = tokenData[6];
    _sellLpTax = tokenData[7];
    _sellRewardTax = tokenData[8];

    _totalBuyFee = _buyDevelopmentTax.add(_buyLpTax).add(_buyRewardTax);
    _totalSellFee = _sellDevelopmentTax.add(_sellLpTax).add(_sellRewardTax);

    developmentWallet = address(uint160(tokenData[1]));
    rewardWallet = address(uint160(tokenData[2]));

    _maxTxAmount = _totalSupply.mul(tokenData[9]).div(100);
    _maxWallet = _totalSupply.mul(tokenData[10]).div(100);

    swapThreshold = tokenData[11] * 10**_decimals;

    IUniswapV2Router02 _dexRouter = IUniswapV2Router02(address(uint160(tokenData[0])));

    dexRouter = _dexRouter;
    
    lpReceiverWallet = owner_;

    isExcludedFromFee[address(this)] = true;
    isExcludedFromFee[owner_] = true;
    isExcludedFromFee[address(dexRouter)] = true;

    isWalletLimitExempt[owner_] = true;
    isWalletLimitExempt[address(dexRouter)] = true;
    isWalletLimitExempt[address(this)] = true;
    isWalletLimitExempt[deadAddress] = true;
    isWalletLimitExempt[zeroAddress] = true;
    
    isTxLimitExempt[deadAddress] = true;
    isTxLimitExempt[zeroAddress] = true;
    isTxLimitExempt[owner_] = true;
    isTxLimitExempt[address(this)] = true;
    isTxLimitExempt[address(dexRouter)] = true;

    _allowances[address(this)][address(dexRouter)] = ~uint256(0);

    _balances[owner_] = _totalSupply;
    emit Transfer(address(0), owner_, _totalSupply);
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view override returns (uint256) {
     return _balances[account];   
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }
  
  function getCirculatingSupply() external view returns (uint256) {
    return _totalSupply.sub(_balances[deadAddress]).sub(_balances[zeroAddress]);
  }

  function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

   //to recieve ETH from Router when swaping
  receive() external payable {}

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: Exceeds allowance"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

    require(sender != address(0));
    require(recipient != address(0));
    require(amount > 0);
  
    if (inSwap) {
      return _basicTransfer(sender, recipient, amount);
    }
    else {

      if (!tradingActive) {
        require(isExcludedFromFee[sender] || isExcludedFromFee[recipient],"Trading is not active.");
      }

      if (launchedAt != 0 && !normalizeTrade) {
        dynamicTaxSetter();
      }

      uint256 contractTokenBalance = _balances[address(this)];
      bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

      if (
        overMinimumTokenBalance && 
        !inSwap && 
        !isMarketPair[sender] && 
        swapEnabled &&
        !isExcludedFromFee[sender] &&
        !isExcludedFromFee[recipient]
        ) {
        swapBack(contractTokenBalance);
      }

      if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && enableTxLimit) {
        require(amount <= _maxTxAmount, "Exceeds maxTxAmount");
      } 
      
      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

      uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeTaxFee(sender, recipient, amount);

      if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
        require(_balances[recipient].add(finalAmount) <= _maxWallet,"Exceeds maxWallet");
      }

      _balances[recipient] = _balances[recipient].add(finalAmount);

      emit Transfer(sender, recipient, finalAmount);
      return true;

    }

  }

  function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
    return true;
  }
  
  function shouldNotTakeFee(address sender, address recipient) internal view returns (bool) {
    if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
      return true;
    }
    else if (isMarketPair[sender] || isMarketPair[recipient]) {
      return false;
    }
    else {
      return false;
    }
  }

  function takeTaxFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
    
    uint feeAmount;

    unchecked {

      if(isMarketPair[sender]) { 
        feeAmount = amount.mul(_totalBuyFee).div(feedenominator);
      } 
      else if(isMarketPair[recipient]) { 
        feeAmount = amount.mul(_totalSellFee).div(feedenominator);
      }

      if(feeAmount > 0) {
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
      }

      return amount.sub(feeAmount);
    }
    
  }

  function launch() external payable onlyOwner {
    require(launchedAt == 0, "Already launched!");
    launchedAt = block.number;
    tradingActive = true;

    uint tokenForLp = _balances[address(this)];

    _buyDevelopmentTax = 1;
    _buyLpTax = 0;
    _buyRewardTax = 0;

    _sellDevelopmentTax = 1;
    _sellLpTax = 0;
    _sellRewardTax = 0;

    dexRouter.addLiquidityETH{ value: msg.value }(
      address(this),
      tokenForLp,
      0,
      0,
      _owner(),
      block.timestamp
    );

    IUniswapV2Factory factory = IUniswapV2Factory(dexRouter.factory());

    IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(this), dexRouter.WETH()));

    dexPair = address(pair);

    isMarketPair[address(dexPair)] = true;
    isWalletLimitExempt[address(dexPair)] = true;
    _allowances[address(this)][address(dexPair)] = ~uint256(0);

    swapEnabled = true;
    enableTxLimit = true;
    checkWalletLimit =  true;
  }

  function dynamicTaxSetter() internal {
    if (block.number <= launchedAt + 3) {
      dynamicSetter(99,99);
    }
    if (block.number > launchedAt + 3 && block.number <= launchedAt + 22) {
      dynamicSetter(45,45);
    }
    if (block.number > launchedAt + 22) {
      dynamicSetter(4,4);
      normalizeTrade = true;
    }
      
  }

  function dynamicSetter(uint _buy, uint _Sell) internal {
    _totalBuyFee = _buy;
    _totalSellFee = _Sell;
  }


  function swapBack(uint contractBalance) internal swapping {

    if(swapByLimit) contractBalance = swapThreshold;

    uint256 totalShares = _totalBuyFee.add(_totalSellFee);

    uint256 _liquidityShare = _buyLpTax.add(_sellLpTax);
    // uint256 _developmentShare = _buydevelopmentTax.add(_selldevelopmentTax);
    uint256 _rewardShare = _buyRewardTax.add(_sellRewardTax);

    uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
    uint256 tokensForSwap = contractBalance.sub(tokensForLP);

    uint256 initialBalance = address(this).balance;
    swapTokensForEth(tokensForSwap);
    uint256 amountReceived = address(this).balance.sub(initialBalance);

    uint256 totalETHFee = totalShares.sub(_liquidityShare.div(2));
    
    uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
    uint256 amountETHReward = amountReceived.mul(_rewardShare).div(totalETHFee);
    uint256 amountETHDevelopment = amountReceived.sub(amountETHLiquidity).sub(amountETHReward);

     if(amountETHReward > 0)
      payable(rewardWallet).transfer(amountETHReward);

    if(amountETHDevelopment > 0)
      payable(developmentWallet).transfer(amountETHDevelopment);

    if(amountETHLiquidity > 0 && tokensForLP > 0)
      addLiquidity(tokensForLP, amountETHLiquidity);

  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(dexRouter), tokenAmount);

    // add the liquidity
    dexRouter.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      lpReceiverWallet,
      block.timestamp
    );
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = dexRouter.WETH();

    _approve(address(this), address(dexRouter), tokenAmount);

    // make the swap
    dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this), // The contract
      block.timestamp
    );
    
    emit SwapTokensForETH(tokenAmount, path);
  }

  function rescueFunds() external onlyGuard { 
    (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
    require(os,"Transaction Failed!!");
  }

  function rescueTokens(address _token, address recipient, uint _amount) external onlyGuard {
    require(_token != address(0), "_token address cannot be 0");
    uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
    require(_contractBalance >= _amount, "Insufficient token balance");
    IERC20(_token).transfer(recipient, _amount);
  }

  function setBuyFee(uint _developmentFee, uint _lpFee, uint _rewardFee) external onlyOwner {  
    _buyDevelopmentTax = _developmentFee;
    _buyLpTax = _lpFee;
    _buyRewardTax = _rewardFee;

    _totalBuyFee = _buyDevelopmentTax.add(_buyLpTax).add(_buyRewardTax);
  }

  function setSellFee(uint _developmentFee, uint _lpFee, uint _rewardFee) external onlyOwner {
    _sellDevelopmentTax = _developmentFee;
    _sellLpTax = _lpFee;
    _sellRewardTax = _rewardFee;
    _totalSellFee = _sellDevelopmentTax.add(_sellLpTax).add(_sellRewardTax);
  }

  function removeLimits() external onlyGuard {
    enableTxLimit = false;
    checkWalletLimit =  false;
  }

  function setEnableTxLimit(bool _status) external onlyOwner {
    enableTxLimit = _status;
  }

  function setEnableWalletLimit(bool _status) external onlyOwner {
    checkWalletLimit = _status;
  }

  function excludeFromFee(address _adr,bool _status) external onlyOwner {
    isExcludedFromFee[_adr] = _status;
  }

  function excludeWalletLimit(address _adr,bool _status) external onlyOwner {
    isWalletLimitExempt[_adr] = _status;
  }

  function excludeTxLimit(address _adr,bool _status) external onlyOwner {
    isTxLimitExempt[_adr] = _status;
  }

  function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
    _maxWallet = newLimit;
  }

  function setTxLimit(uint256 newLimit) external onlyOwner() {
    _maxTxAmount = newLimit;
  }
  
  function setDevelopmentWallet(address _newWallet) external onlyOwner {
    developmentWallet = _newWallet;
  }

  function setLpWallet(address _newWallet) external onlyOwner {
    lpReceiverWallet = _newWallet;
  }

  function setRewardWallet(address _newWallet) external onlyOwner {
    rewardWallet = _newWallet;
  }

  function setMarketPair(address _pair, bool _status) external onlyOwner {
    isMarketPair[_pair] = _status;
    if(_status) {
      isWalletLimitExempt[_pair] = _status;
    }
  }

  function setSwapBackSettings(uint _threshold, bool _enabled, bool _limited)
    external
    onlyGuard
  {
    swapEnabled = _enabled;
    swapByLimit = _limited;
    swapThreshold = _threshold;
  }

  function setManualRouter(address _router) external onlyOwner {
    dexRouter = IUniswapV2Router02(_router);
  }

  function setManualPair(address _pair) external onlyOwner {
    dexPair = _pair;
  }

  function getTokenData() external view returns (
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 totalBalance_,
    uint256 launchedAt_,
    address owner_,
    address dexPair_
  ) {
    name_ = _name;
    symbol_ = _symbol;
    decimals_ = _decimals;
    totalSupply_ = _totalSupply;
    totalBalance_ = _balances[address(this)];
    launchedAt_ = launchedAt;
    owner_ = _owner();
    dexPair_ = dexPair;
  }
}