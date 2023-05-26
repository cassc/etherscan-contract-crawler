// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Momento is IERC20Metadata, Ownable {
  struct User {
    uint256 buy;
    uint256 sell;
  }

  address public marketingAddress = 0x07c013fba1bB7CA3a3eb1dc0666De5bB0bF8D7d9;
  address public stakingAddress = 0x305025F712961a7482A4053b39ac0Fd344206726;
  address public constant deadAddress =
    0x000000000000000000000000000000000000dEaD;

  uint256 private _rStakingLock;

  uint256 public stakingUnlockTime;
  uint8 public stakingUnlockCount;
  uint8 private _rStakingUnlockMonths;
  uint256 private _rStakingUnlockTokenCount;

  uint256 private _rBurnLock;

  uint256 private _rBuyBackTokenCount;

  uint256 private _maxSecondsBetweenBuySell = 15;
  mapping(address => User) private _cooldown;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isUniswapV2Pair;

  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isExcluded;
  address[] private _excludedFromReward;

  uint256 private _holderCount;
  uint256 private _lastMaxHolderCount = 99;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal = 1000000000000 * 10**9;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  string private _name = 'Momento';
  string private _symbol = 'MOMENTO';

  uint256 public _taxFee = 3;
  uint256 private _previousTaxFee = _taxFee;

  uint256 public _liquidityFee = 3;
  uint256 private _previousLiquidityFee = _liquidityFee;

  uint256 public _buyBackFee = 4;
  uint256 private _previousBuyBackFee = _buyBackFee;
  uint256 private _buyBackEthBalance;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public uniswapV2Pair;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 private numTokensSellToAddToLiquidity = 500000000 * 10**9;

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );
  event SwapETHForTokens(uint256 amountIn, address[] path);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor() {
    // 1% of total reflection supply
    uint256 onePercentR = _rTotal / 100;
    // 1% of total t supply
    // uint256 onePercentT = _tTotal / 100;

    // add 60% of tokens to owner(for adding to liquidity pool)
    _rOwned[_msgSender()] = onePercentR * 60;
    // add 2% of tokens to marketing address
    _rOwned[marketingAddress] = onePercentR * 2;

    // 12% is allocated for staking, 90% of that of which is vested over 12 months,
    // 10% that goes directly to stakingAddress right away
    uint256 _rStakingTotal = onePercentR * 12;
    _rStakingLock = (_rStakingTotal / 10) * 9;
    _rOwned[address(0)] = _rStakingLock;
    _rOwned[stakingAddress] = _rStakingTotal - _rStakingLock;

    _rStakingUnlockMonths = 12;
    _rStakingUnlockTokenCount = _rStakingLock / _rStakingUnlockMonths;
    // keep here until we confirm we don't want to have a locking period
    stakingUnlockTime = block.timestamp; // + 0 days;

    // burning 26% of total supply here
    _rOwned[deadAddress] = onePercentR * 26;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    // Create a uniswap pair for this new token
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    // set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;

    _holderCount = 4;

    _isUniswapV2Pair[uniswapV2Pair] = true;

    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    emit Transfer(
      address(0),
      _msgSender(),
      tokenFromReflection(_rOwned[_msgSender()])
    );
    emit Transfer(
      address(0),
      marketingAddress,
      tokenFromReflection(_rOwned[marketingAddress])
    );
    emit Transfer(
      address(0),
      stakingAddress,
      tokenFromReflection(_rOwned[stakingAddress])
    );
    emit Transfer(
      address(0),
      address(0),
      tokenFromReflection(_rOwned[address(0)])
    );
    emit Transfer(
      address(0),
      deadAddress,
      tokenFromReflection(_rOwned[deadAddress])
    );
  }

  function unlockStakingTokens() external {
    require(
      _msgSender() == stakingAddress,
      'Function can be called only with staking address'
    );
    require(
      block.timestamp > stakingUnlockTime,
      'Function can be called only if stakingUnlockTime has passed'
    );
    require(
      stakingUnlockCount < _rStakingUnlockMonths,
      'You are already unlocked all tokens'
    );
    uint256 difference = block.timestamp - stakingUnlockTime;
    uint256 monthCount = difference / 30 days;
    uint8 remainingMonths = _rStakingUnlockMonths - stakingUnlockCount;
    if (monthCount > remainingMonths) monthCount = remainingMonths;
    uint256 amountToTransfer = monthCount * _rStakingUnlockTokenCount;
    if (amountToTransfer > 0) {
      _rOwned[address(0)] -= amountToTransfer;
      _rOwned[stakingAddress] += amountToTransfer;
      stakingUnlockCount += uint8(monthCount);
      stakingUnlockTime += monthCount * 30 days;
      emit Transfer(
        address(0),
        stakingAddress,
        tokenFromReflection(amountToTransfer)
      );
    }
  }

  function setMarketingAddress(address _marketingAddress) public onlyOwner {
    marketingAddress = _marketingAddress;
  }

  function setStakingAddress(address _stakingAddress) public onlyOwner {
    stakingAddress = _stakingAddress;
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function decimals() public pure override returns (uint8) {
    return 9;
  }

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] - subtractedValue
    );
    return true;
  }

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }

  function deliver(uint256 tAmount) public {
    address sender = _msgSender();
    require(
      !_isExcluded[sender],
      'Excluded addresses cannot call this function'
    );
    uint256 rAmount = tAmount * _getRate();
    _rOwned[sender] -= rAmount;
    _rTotal -= rAmount;
    _tFeeTotal += tAmount;
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    public
    view
    returns (uint256)
  {
    require(tAmount <= _tTotal, 'Amount must be less than supply');
    uint256 currentRate = _getRate();
    if (!deductTransferFee) {
      return tAmount * currentRate;
    } else {
      uint256[4] memory tValues = _getTValues(tAmount);
      return tValues[0] * currentRate;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, 'Amount must be less than total reflections');
    uint256 currentRate = _getRate();
    return rAmount / currentRate;
  }

  function excludeFromReward(address account) public onlyOwner {
    require(!_isExcluded[account], 'Account is already excluded');
    require(
      account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
      'We can not exclude Uniswap router.'
    );
    require(account != marketingAddress, 'marketingAddress cannot be excluded');
    require(account != deadAddress, 'deadAddress cannot be excluded');
    require(
      _excludedFromReward.length <= 40,
      "Don't allow too many excluded addresses"
    );
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excludedFromReward.push(account);
  }

  function includeInReward(address account) external onlyOwner {
    require(_isExcluded[account], 'Account is already excluded');
    for (uint256 i = 0; i < _excludedFromReward.length; i++) {
      if (_excludedFromReward[i] == account) {
        _excludedFromReward[i] = _excludedFromReward[
          _excludedFromReward.length - 1
        ];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excludedFromReward.pop();
        break;
      }
    }
  }

  function addUniswapV2PairAddress(address account) external onlyOwner {
    _isUniswapV2Pair[account] = true;
  }

  function removeUniswapV2PairAddress(address account) external onlyOwner {
    _isUniswapV2Pair[account] = false;
  }

  function setMaxSecondsBetweenBuySell(uint256 _seconds) external onlyOwner {
    _maxSecondsBetweenBuySell = _seconds;
  }

  function setTaxFeePercent(uint256 taxFee) external onlyOwner {
    _taxFee = taxFee;
  }

  function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
    _liquidityFee = liquidityFee;
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}

  function _reflectFee(uint256 tFee, uint256 rFee) private {
    _rTotal -= rFee;
    _tFeeTotal += tFee;
  }

  // tValues[0] -> tTransferAmount -> transfer amount
  // tValues[1] -> tFee -> holders fee amount
  // tValues[2] -> tLiquidity -> liquidity fee amount
  // tValues[3] -> tBuyBack -> buyBack fee amount
  function _getTValues(uint256 tAmount)
    private
    view
    returns (uint256[4] memory)
  {
    uint256[4] memory tValues;
    tValues[1] = calculateTaxFee(tAmount); // tFee
    tValues[2] = calculateLiquidityFee(tAmount); // tLiquidity
    tValues[3] = calculateBuyBackFee(tAmount); // tBuyBack
    tValues[0] = tAmount - tValues[1] - tValues[2] - tValues[3]; // tTransferAmount
    return tValues;
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply / tSupply;
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excludedFromReward.length; i++) {
      if (
        _rOwned[_excludedFromReward[i]] > rSupply ||
        _tOwned[_excludedFromReward[i]] > tSupply
      ) return (_rTotal, _tTotal);
      rSupply -= _rOwned[_excludedFromReward[i]];
      tSupply -= _tOwned[_excludedFromReward[i]];
    }
    if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity, uint256 rLiquidity) private {
    _rOwned[address(this)] += rLiquidity;
    if (_isExcluded[address(this)]) {
      _tOwned[address(this)] += tLiquidity;
    }
  }

  function calculateTaxFee(uint256 _amount) private view returns (uint256) {
    return (_amount * _taxFee) / 100;
  }

  function calculateLiquidityFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    return (_amount * _liquidityFee) / 100;
  }

  function calculateBuyBackFee(uint256 _amount) private view returns (uint256) {
    return (_amount * _buyBackFee) / 100;
  }

  function removeAllFee() private {
    if (_taxFee == 0 && _liquidityFee == 0 && _buyBackFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;
    _previousBuyBackFee = _buyBackFee;

    _taxFee = 0;
    _liquidityFee = 0;
    _buyBackFee = 0;
  }

  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
    _buyBackFee = _previousBuyBackFee;
  }

  function isUniswapV2PairAddress(address account) public view returns (bool) {
    return _isUniswapV2Pair[account];
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(amount > 0, 'Transfer amount must be greater than zero');

    // if balance of recipient is 0 then holder count is increased
    // and if sender balance is equal to amount then holder count decreased
    if (balanceOf(to) == 0) _holderCount++;
    if (balanceOf(from) == amount) _holderCount--;

    // indicates if fee should be deducted from transfer
    bool takeFee;
    uint256 timestamp = block.timestamp;

    // take fee only in buying or selling operation
    if (from != address(this) && to != address(this)) {
      // buy
      if (
        _isUniswapV2Pair[from] &&
        to != address(uniswapV2Router) &&
        !_isExcludedFromFee[to]
      ) {
        _cooldown[to].sell = timestamp + _maxSecondsBetweenBuySell;
        takeFee = true;
      } else {
        // sell
        if (_isUniswapV2Pair[to]) {
          takeFee = true;
          require(
            _cooldown[from].sell < timestamp,
            'You can sell tokens once in _maxSecondsBetweenBuySell seconds'
          );
          _cooldown[from].sell = timestamp + _maxSecondsBetweenBuySell;

          // is the token balance of this contract address over the min number of
          // tokens that we need to initiate a swap + liquidity lock?
          // also, don't get caught in a circular liquidity event.
          // also, don't swap & liquify if sender is uniswap pair.
          uint256 contractTokenBalance = balanceOf(address(this));

          bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
          if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !_isUniswapV2Pair[from] &&
            swapAndLiquifyEnabled
          ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            // add liquidity
            swapAndLiquify(contractTokenBalance);
          }
        }
      }
    }

    // if sender is excluded or recipient is excluded then fee does not taken
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    // transfer amount, it will take tax, burn, liquidity, marketing fee
    _tokenTransfer(from, to, amount, takeFee);
  }

  function buyBackAndBurn(uint256 _amountETH) external onlyOwner {
    if (_amountETH == 0) _amountETH = _buyBackEthBalance;
    require(
      _buyBackEthBalance >= _amountETH,
      'trying to buy back and burn more than balance available'
    );
    if (_amountETH > 0) {
      _buyBackAndBurn(_amountETH);
      _buyBackEthBalance -= _amountETH;
    }
  }

  function _buyBackAndBurn(uint256 amount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = address(this);

    uint256 _deadBalBefore = balanceOf(deadAddress);
    // make the swap
    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: amount
    }(
      0, // accept any amount of Tokens
      path,
      deadAddress, // Burn address
      block.timestamp
    );

    emit SwapETHForTokens(amount, path);
    emit Transfer(
      address(this),
      deadAddress,
      balanceOf(deadAddress) - _deadBalBefore
    );
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into halves
    uint256 half = contractTokenBalance / 2;
    uint256 otherHalf = contractTokenBalance - half;

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into taking buyBack balance into consideration?
    uint256 newBalance = address(this).balance - initialBalance;

    // add liquidity to uniswap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
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
      address(this),
      block.timestamp
    );
  }

  // this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 tAmount,
    bool takeFee
  ) private {
    if (!takeFee) {
      removeAllFee();
    }

    // tValues[0] -> tTransferAmount -> transfer amount
    // tValues[1] -> tFee -> holders fee amount
    // tValues[2] -> tLiquidity -> liquidity fee amount
    // tValues[3] -> tBuyBack -> buyBack fee amount
    uint256[4] memory tValues = _getTValues(tAmount);
    uint256 currentRate = _getRate();
    if (takeFee) {
      _rBuyBackTokenCount += (tValues[3] * currentRate);
      if (!_isUniswapV2Pair[sender] && _rBuyBackTokenCount > 0) {
        uint256 _tBuyBackTokenCount = _rBuyBackTokenCount / currentRate;
        address contractAddress = address(this);
        _rOwned[contractAddress] += _rBuyBackTokenCount;
        emit Transfer(sender, contractAddress, _tBuyBackTokenCount);
        uint256 _balBefore = contractAddress.balance;
        swapTokensForEth(_tBuyBackTokenCount);
        _buyBackEthBalance += contractAddress.balance - _balBefore;
        _rBuyBackTokenCount = 0;
      }

      _takeLiquidity(tValues[2], tValues[2] * currentRate);
      _reflectFee(tValues[1], tValues[1] * currentRate);
    }
    _rOwned[sender] -= (tAmount * currentRate);
    _rOwned[recipient] += (tValues[0] * currentRate);
    if (_isExcluded[sender]) {
      _tOwned[sender] -= tAmount;
    }
    if (_isExcluded[recipient]) {
      _tOwned[recipient] += tValues[0];
    }
    emit Transfer(sender, recipient, tValues[0]);

    if (!takeFee) {
      restoreAllFee();
    }
  }
}