/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}
interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}
interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

 contract TOKEN is IERC20, Ownable {

  uint256 private constant _totalTokens = 1_234_567_890 * 10**DECIMALS;
  string private constant NAME = "CHESS";
  string private constant SYMBOL = "CES";
  uint8 private constant DECIMALS = 18;

  struct feeProfile{ uint8 _liquidity; uint8 _marketing; uint8 _dev; uint8 _totalFee; }

  feeProfile public _buyProfile;
  feeProfile public _sellProfile;
       
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => uint256) private _balances;
  mapping (address => bool) public _addressesExcludedFromFees;

  bool public _isSwapEnabled;
  bool public _isFeeEnabled;
  bool public _isBuyingAllowed; //The contract will be activated once liquidity is added.

  uint256 public _tokenSwapThreshold = _totalTokens / 1000 * 1; //0.1%

  // UNISWAP INTERFACES (For swaps)
  IRouter02 internal V2Router;
  address private V2Pair;

  address public _marketingWallet;
  address public _devWallet;

  uint256 private blockPenalty;
  uint256 public tradingActiveBlock = 0; // 0 means trading is not active

  event _changeFees(uint256 _liq, uint256 _marketing, uint256 _dev, bool _isBuy);
  event _updateWallets(address _marketing, address _dev);
  event _setRouter(address _routerAddress);
  event _setThreshold(uint256 _threshold);
  event _clear(uint256 _tokenAmount);
  event _claimDust(uint256 _amount);
  event _launch(uint256 _start);
  event _swapAndLiquify(uint256 _amount);
   
  constructor () {
    _balances[_msgSender()] = totalSupply();
    _marketingWallet = address(0x9AF927F3Ba2b2Ccebb7f9169DB62F9c8c7a5B5D1);
    _devWallet = address(0xeAfC73DE25590Bc1b8f6D16453c1A70b47A38655);

    // Initialize V2 router
    setSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // Exclude contract from fees
    setExcludedFromFees(address(this), true);
    setExcludedFromFees(_msgSender(), true);
    setExcludedFromFees(_marketingWallet, true);
    setExcludedFromFees(_devWallet, true);

    // buy
    setFeeProfile(0,0,0,true);

    // sell
    setFeeProfile(0,0,0,false);

    emit Transfer(address(0), _msgSender(), totalSupply());
  }

  function Launch(uint256 _blockPenalty) external onlyOwner {
    require(!_isBuyingAllowed, "trading is already active");
 
    setSwapEnabled(true);
    setFeeEnabled(true);

    _isBuyingAllowed = true;
    tradingActiveBlock = block.number;
    blockPenalty = _blockPenalty;

    emit _launch(tradingActiveBlock);
  }

  function setWallets(address _marketing, address _dev) external onlyOwner() {
        _marketingWallet = _marketing;
        _devWallet = _dev;
        emit _updateWallets(_marketing, _dev);
    }

  function setFeeProfile(uint8 _liquidity, uint8 _marketing, uint8 _dev, bool _updateBuy) public onlyOwner() {
    uint8 _totalFee = _liquidity + _marketing + _dev;
    require(_totalFee <= 20, "tax to high");
        if(_updateBuy) { _buyProfile._liquidity = _liquidity;  _buyProfile._marketing = _marketing;  _buyProfile._dev = _dev; _buyProfile._totalFee = _totalFee; }
        else{ _sellProfile._liquidity = _liquidity; _sellProfile._marketing = _marketing; _sellProfile._dev = _dev; _sellProfile._totalFee = _totalFee;}
        emit _changeFees(_liquidity,_marketing,_dev,_updateBuy);
    }
   
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    doTransfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    doTransfer(sender, recipient, amount);
    doApprove(sender, _msgSender(), _allowances[sender][_msgSender()] - amount); // Will fail when there is not enough allowance
    return true;
  }
 
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    doApprove(_msgSender(), spender, amount);
    return true;
  }
 
  function doTransfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "zero address transfer is not allowed");
    require(recipient != address(0), "zero address transfer is not allowed");
    require(amount > 0, "amount must be greater than zero");

    if(!_isBuyingAllowed)  { require(_addressesExcludedFromFees[sender], "cant transfer"); }
    if(_isSwapEnabled){executeSwapCheck(sender, recipient); }

    uint256 feeRate = calculateFeeRate(sender, recipient);
    uint256 feeAmount = amount * feeRate / 100;
    uint256 transferAmount = amount - feeAmount;

    updateBalances(sender, recipient, amount, feeAmount);

    emit Transfer(sender, recipient, transferAmount);
  }
 
  function executeSwapCheck(address sender, address recipient) private {
    if (!isMarketTransfer(sender, recipient)) {
      return;
    }

    uint256 tokensAvailableForSwap = balanceOf(address(this));
    if (tokensAvailableForSwap >= _tokenSwapThreshold) {
      tokensAvailableForSwap = _tokenSwapThreshold;

      bool isSelling = isPancakeswapPair(recipient);
      if (isSelling) {
        executeSwap(tokensAvailableForSwap);
      }
    }
  }

  // if buildup becomes to large in contract
  function clearSwap(uint256 _tokenAmount) external onlyOwner(){
    executeSwap(_tokenAmount);
    emit _clear(_tokenAmount);
  }
 
  function executeSwap(uint256 amount) private {
    // Allow pancakeswap to spend the tokens of the address
    doApprove(address(this), address(V2Router), amount);
    uint256 total = _sellProfile._totalFee;

    if(total > 0 ){
      uint256 tokensReservedForLiquidity = amount * _sellProfile._liquidity / total;
      uint256 tokensReservedForDev = amount * _sellProfile._dev / total ;
      uint256 tokensReservedForMarketing = amount - tokensReservedForLiquidity - tokensReservedForDev;

      uint256 tokensToSwapForLiquidity = tokensReservedForLiquidity / 2;
      uint256 tokensToAddAsLiquidity = tokensToSwapForLiquidity;

      uint256 tokensToSwap = tokensToSwapForLiquidity + tokensReservedForMarketing + tokensReservedForDev;
      uint256 ethSwapped = swapTokensForBNB(tokensToSwap);
     
      uint256 bnbToBeAddedToLiquidity = ethSwapped * tokensToSwapForLiquidity / tokensToSwap;
      uint256 bnbToBeSentToDevelopment = ethSwapped * tokensReservedForDev / tokensToSwap;
      uint256 bnbToBeSentToMarketing = ethSwapped - bnbToBeAddedToLiquidity- bnbToBeSentToDevelopment;

      payable(_marketingWallet).transfer(bnbToBeSentToMarketing);
      payable(_devWallet).transfer(bnbToBeSentToDevelopment);

      try V2Router.addLiquidityETH{value: bnbToBeAddedToLiquidity}(address(this), tokensToAddAsLiquidity, 0, 0, _devWallet, block.timestamp){} catch {}
      emit _swapAndLiquify(ethSwapped);
    }
  }

  function updateBalances(address sender, address recipient, uint256 sentAmount, uint256 feeAmount) private {
    // Calculate amount to be received by recipient
    uint256 receivedAmount = sentAmount - feeAmount;

    // Update balances
    _balances[sender] -= sentAmount;
    _balances[recipient] += receivedAmount;
   
    // Add fees to contract
    _balances[address(this)] += feeAmount;

    // hides bloat emits
    if(feeAmount > 0 ){
      emit Transfer(sender, address(this), feeAmount);
    }
 
  }

  function doApprove(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "Cannot approve from the zero address");
    require(spender != address(0), "Cannot approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function calculateFeeRate(address sender, address recipient) private view returns(uint256) {
    bool applyFees = _isFeeEnabled && !_addressesExcludedFromFees[sender] && !_addressesExcludedFromFees[recipient];
    if (applyFees) {
      if (isPancakeswapPair(recipient)) {
        return _sellProfile._totalFee;
      }else{
            if(isPenaltyActive()){
                return 75;
              }else{
                return _buyProfile._totalFee;
              }
            }
    }
    return 0;
  }
 
  function swapTokensForBNB(uint256 tokenAmount) internal returns(uint256) {
    uint256 initialBalance = address(this).balance;
 
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = V2Router.WETH();
    V2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
 
    return address(this).balance - initialBalance;
  }

  function isSwapTransfer(address sender, address recipient) private view returns(bool) {
    bool isContractSelling = sender == address(this) && isPancakeswapPair(recipient);
    return isContractSelling;
  }

  function isMarketTransfer(address sender, address recipient) internal virtual view returns(bool) {
    return !isSwapTransfer(sender, recipient);
  }

  function amountUntilSwap() external  view returns (uint256) {
    uint256 balance = balanceOf(address(this));
    if (balance > _tokenSwapThreshold) {
      return 0;
    }
    return _tokenSwapThreshold - balance;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    doApprove(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  function setSwapRouter(address routerAddress) public onlyOwner {
    require(routerAddress != address(0), "Cannot use the zero address as router address");
    V2Router = IRouter02(routerAddress);
    V2Pair = IFactoryV2(V2Router.factory()).createPair(address(this), V2Router.WETH());
    emit _setRouter(routerAddress);
  }

  function isPancakeswapPair(address addr) internal view returns(bool) {
    return V2Pair == addr;
  }

  function setTokenSwapThreshold(uint256 threshold) external  onlyOwner {
    require(threshold > 0, "Threshold must be greater than 0");
    _tokenSwapThreshold = threshold;
    emit _setThreshold(threshold);
  }

  // dust can build up by failure of adding liq
  function clearDust() external  onlyOwner{
      payable(_devWallet).transfer(address(this).balance);
      emit _claimDust(address(this).balance);
  }

    function totalSupply() public override pure returns (uint256) { return _totalTokens; }
    function allowance(address user, address spender) public view override returns (uint256) { return _allowances[user][spender]; }
    function pairAddress() public view returns (address) { return V2Pair; }
    function setSwapEnabled(bool isEnabled) public onlyOwner { _isSwapEnabled = isEnabled; }
    function setFeeEnabled(bool isEnabled) public onlyOwner { _isFeeEnabled = isEnabled; }
    function setExcludedFromFees(address addr, bool value) public onlyOwner { _addressesExcludedFromFees[addr] = value; }
    function isPenaltyActive() public view returns (bool) { return tradingActiveBlock >= block.number - blockPenalty; }
    function decimals() external pure override returns (uint8) { if (totalSupply() == 0) { revert(); } return DECIMALS; }
    function symbol() external pure override returns (string memory) { return SYMBOL; }
    function name() external pure override returns (string memory) { return NAME; }
    function getOwner() external view override returns (address) { return owner(); }

  receive() external payable {}
}