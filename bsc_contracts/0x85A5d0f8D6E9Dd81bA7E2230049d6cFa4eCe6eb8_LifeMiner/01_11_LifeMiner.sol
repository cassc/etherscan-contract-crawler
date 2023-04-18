// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ERC20.sol";
import "./IPancake.sol";
import "./GasHelper.sol";
import "./SwapHelper.sol";

contract LifeMiner is GasHelper, ERC20 {
  string public constant URL = "https://www.mpytoken.com";

  address constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address constant ZERO = 0x0000000000000000000000000000000000000000;
  address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // ? PROD
  

  address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // ? PROD

  string constant NAME = "LIFE MINER";
  string constant SYMBOL = "MPY TOKEN";

  uint constant MAX_SUPPLY = 300_000_000e18;

  // Wallets limits
  uint public maxTxAmount = MAX_SUPPLY;
  uint public maxAccountAmount = MAX_SUPPLY;
  uint public minAmountToAutoSwap = 1000 * (10**decimals()); // 100

  // Fees
  uint public feePool = 400;
  uint public feeBurnRate = 200;
  uint public feeAdministrationWallet = 200;
  uint public feeMarketingWallet = 200;

  uint constant MAX_TOTAL_FEE = 1000;

  mapping(address => uint) public specialFeesByWalletSender;
  mapping(address => uint) public specialFeesByWalletReceiver;

  // Helpers
  bool private _noReentrance;

  bool public disablePoolFeeSwap;
  bool public disableAdminFeeSwap;
  bool public disableMarketingFeeSwap;
  bool public disabledAutoLiquidity;

  // Counters
  uint public accumulatedToAdmin;
  uint public accumulatedToMarketing;
  uint public accumulatedToPool;

  // Liquidity Pair
  address public liquidityPool;

  // Wallets
  address public administrationWallet;
  address public marketingWallet;

  address public swapHelperAddress;

  receive() external payable {}

  constructor() ERC20(NAME, SYMBOL) {
    PancakeRouter router = PancakeRouter(PANCAKE_ROUTER);
    liquidityPool = address(PancakeFactory(router.factory()).createPair(WBNB, address(this)));

    uint baseAttributes = 0;
    baseAttributes = _setExemptAmountLimit(baseAttributes, true);
    _attributeMap[liquidityPool] = baseAttributes;

    baseAttributes = _setExemptTxLimit(baseAttributes, true);
    _attributeMap[DEAD] = baseAttributes;
    _attributeMap[ZERO] = baseAttributes;

    baseAttributes = _setExemptFeeSender(baseAttributes, true);
    _attributeMap[address(this)] = baseAttributes;

    baseAttributes = _setExemptSwapperMaker(baseAttributes, true);
    baseAttributes = _setExemptFeeReceiver(baseAttributes, true);

    _attributeMap[_msgSender()] = baseAttributes;

    SwapHelper swapHelper = new SwapHelper();
    swapHelper.safeApprove(WBNB, address(this), type(uint).max);
    swapHelper.transferOwnership(_msgSender());
    swapHelperAddress = address(swapHelper);

    _attributeMap[swapHelperAddress] = baseAttributes;

    _mint(_msgSender(), MAX_SUPPLY);
  }

  // ----------------- Public Views -----------------

  function getFeeTotal() public view returns (uint) {
    return feePool + feeBurnRate + feeAdministrationWallet + feeMarketingWallet;
  }

  function getSpecialWalletFee(address target, bool isSender)
    public
    view
    returns (
      uint pool,
      uint burnRate,
      uint adminFee,
      uint marketingFee
    )
  {
    uint composedValue = isSender ? specialFeesByWalletSender[target] : specialFeesByWalletReceiver[target];
    pool = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    burnRate = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    adminFee = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    marketingFee = composedValue % 1e4;
  }

  // ----------------- Authorized Methods -----------------

  function setLiquidityPool(address newPair) external onlyOwner {
    require(newPair != ZERO, "Invalid address");
    liquidityPool = newPair;
  }

  function setSwapPoolFeeDisabled(bool state) external onlyOwner {
    disablePoolFeeSwap = state;
  }

  function setSwapAdminFeeDisabled(bool state) external onlyOwner {
    disableAdminFeeSwap = state;
  }

  function setSwapMarketingFeeDisabled(bool state) external onlyOwner {
    disableMarketingFeeSwap = state;
  }

  function setDisabledAutoLiquidity(bool state) external onlyOwner {
    disabledAutoLiquidity = state;
  }

  // ----------------- Wallets Settings -----------------
  function setAdministrationWallet(address account) public onlyOwner {
    require(account != ZERO, "Invalid address");
    administrationWallet = account;
  }

  function setMarketingWallet(address account) public onlyOwner {
    require(account != ZERO, "Invalid address");
    marketingWallet = account;
  }

  // ----------------- Fee Settings -----------------
  function setFees(
    uint pool,
    uint burnRate,
    uint administration,
    uint feeMarketing
  ) external onlyOwner {
    feePool = pool;
    feeBurnRate = burnRate;
    feeAdministrationWallet = administration;
    feeMarketingWallet = feeMarketing;
    require(getFeeTotal() <= MAX_TOTAL_FEE, "All fee together must be lower than 10%");
  }

  function setSpecialWalletFeeOnSend(
    address target,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) public onlyOwner {
    _setSpecialWalletFee(target, true, pool, burnRate, adminFee, marketingFee);
  }

  function setSpecialWalletFeeOnReceive(
    address target,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) public onlyOwner {
    _setSpecialWalletFee(target, false, pool, burnRate, adminFee, marketingFee);
  }

  function _setSpecialWalletFee(
    address target,
    bool isSender,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) private {
    uint total = pool + burnRate + adminFee + marketingFee;
    require(total <= MAX_TOTAL_FEE, "All rates and fee together must be lower than 10%");
    uint composedValue = (pool) + (burnRate * 1e4) + (adminFee * 1e8) + (marketingFee * 1e12);
    if (isSender) {
      specialFeesByWalletSender[target] = composedValue;
    } else {
      specialFeesByWalletReceiver[target] = composedValue;
    }
  }

  // ----------------- Token Flow Settings -----------------
  function setMaxTxAmount(uint maxTxAmount_) public onlyOwner {
    require(maxTxAmount_ >= MAX_SUPPLY / 100_000, "Amount must be bigger then 0.001% tokens");
    maxTxAmount = maxTxAmount_;
  }

  function setMaxAccountAmount(uint maxAccountAmount_) public onlyOwner {
    require(maxAccountAmount_ >= MAX_SUPPLY / 100_000, "Amount must be bigger then 0.001% tokens");
    maxAccountAmount = maxAccountAmount_;
  }

  function setMinAmountToAutoSwap(uint amount) public onlyOwner {
    minAmountToAutoSwap = amount;
  }

  struct Receivers {
    address wallet;
    uint amount;
  }

  function multiTransfer(address[] calldata wallets, uint[] calldata amount) external {
    uint length = wallets.length;
    require(amount.length == length, "Invalid size os lists");
    for (uint i = 0; i < length; i++) transfer(wallets[i], amount[i]);
  }

  // ----------------- External Methods -----------------
  function burn(uint amount) external {
    _burn(_msgSender(), amount);
  }

  // ----------------- Internal CORE -----------------
  function _transfer(
    address sender,
    address receiver,
    uint amount
  ) internal override {
    require(amount > 0, "Invalid Amount");
    require(!_noReentrance, "ReentranceGuard Alert");
    _noReentrance = true;

    uint senderAttributes = _attributeMap[sender];
    uint receiverAttributes = _attributeMap[receiver];

    // Initial Checks
    require(sender != ZERO && receiver != ZERO, "transfer from / to the zero address");
    require(amount <= maxTxAmount || _isExemptTxLimit(senderAttributes), "Exceeded the maximum transaction limit");

    uint senderBalance = _balances[sender];
    require(senderBalance >= amount, "Transfer amount exceeds your balance");
    senderBalance -= amount;
    _balances[sender] = senderBalance;

    uint adminFee;
    uint poolFee;
    uint burnFee;
    uint marketingFee;
    uint feeAmount;

    // Calculate Fees
    if (!_isExemptFeeSender(senderAttributes) && !_isExemptFeeReceiver(receiverAttributes)) {
      if (_isSpecialFeeWalletSender(senderAttributes)) {
        (poolFee, burnFee, adminFee, marketingFee) = getSpecialWalletFee(sender, true); // Check special wallet fee on sender
      } else if (_isSpecialFeeWalletReceiver(receiverAttributes)) {
        (poolFee, burnFee, adminFee, marketingFee) = getSpecialWalletFee(receiver, false); // Check special wallet fee on receiver
      } else {
        adminFee = feeAdministrationWallet;
        poolFee = feePool;
        burnFee = feeBurnRate;
        marketingFee = feeMarketingWallet;
      }
      feeAmount = ((poolFee + burnFee + adminFee + marketingFee) * amount) / 10_000;
    }

    if (feeAmount != 0) _splitFee(feeAmount, sender, adminFee, poolFee, burnFee, marketingFee);
    if ((!disablePoolFeeSwap || !disableAdminFeeSwap || !disableMarketingFeeSwap) && !_isExemptSwapperMaker(senderAttributes)) _autoSwap(sender);

    // Update Recipient Balance
    uint newRecipientBalance = _balances[receiver] + (amount - feeAmount);
    _balances[receiver] = newRecipientBalance;
    require(newRecipientBalance <= maxAccountAmount || _isExemptAmountLimit(receiverAttributes), "Exceeded the maximum tokens an wallet can hold");

    _noReentrance = false;
    emit Transfer(sender, receiver, amount - feeAmount);
  }

  function _operateSwap(
    address liquidityPair,
    address swapHelper,
    uint amountIn
  ) private returns (uint) {
    (uint112 reserve0, uint112 reserve1) = _getTokenReserves(liquidityPair);
    bool reversed = _isReversed(liquidityPair, WBNB);

    if (reversed) {
      uint112 temp = reserve0;
      reserve0 = reserve1;
      reserve1 = temp;
    }

    _balances[liquidityPair] += amountIn;
    uint wbnbAmount = _getAmountOut(amountIn, reserve1, reserve0);
    if (!reversed) {
      _swapToken(liquidityPair, wbnbAmount, 0, swapHelper);
    } else {
      _swapToken(liquidityPair, 0, wbnbAmount, swapHelper);
    }
    return wbnbAmount;
  }

  function _autoSwap(address sender) private {
    // --------------------- Execute Auto Swap -------------------------
    address liquidityPair = liquidityPool;
    address swapHelper = swapHelperAddress;

    if (sender == liquidityPair) return;

    uint poolAmount = disabledAutoLiquidity ? accumulatedToPool : (accumulatedToPool / 2);
    uint adminAmount = accumulatedToAdmin;
    uint marketingAmount = accumulatedToMarketing;
    uint totalAmount = poolAmount + adminAmount + marketingAmount;

    if (totalAmount < minAmountToAutoSwap) return;

    // Execute auto swap
    uint amountOut = _operateSwap(liquidityPair, swapHelper, totalAmount);

    // --------------------- Add Liquidity -------------------------
    if (poolAmount > 0) {
      if (!disabledAutoLiquidity) {
        uint amountToSend = (amountOut * poolAmount) / (totalAmount);
        (uint112 reserve0, uint112 reserve1) = _getTokenReserves(liquidityPair);
        bool reversed = _isReversed(liquidityPair, WBNB);
        if (reversed) {
          uint112 temp = reserve0;
          reserve0 = reserve1;
          reserve1 = temp;
        }

        uint amountA;
        uint amountB;
        {
          uint amountBOptimal = (amountToSend * reserve1) / reserve0;
          if (amountBOptimal <= poolAmount) {
            (amountA, amountB) = (amountToSend, amountBOptimal);
          } else {
            uint amountAOptimal = (poolAmount * reserve0) / reserve1;
            assert(amountAOptimal <= amountToSend);
            (amountA, amountB) = (amountAOptimal, poolAmount);
          }
        }
        _tokenTransferFrom(WBNB, swapHelper, liquidityPair, amountA);
        _balances[liquidityPair] += amountB;
        IPancakePair(liquidityPair).mint(address(this));
      } else {
        uint amountToSend = (amountOut * poolAmount) / (totalAmount);
        _tokenTransferFrom(WBNB, swapHelper, address(this), amountToSend);
      }
    }

    // --------------------- Transfer Swapped Amount -------------------------
    if (adminAmount > 0) {
      uint amountToSend = (amountOut * adminAmount) / (totalAmount);
      _tokenTransferFrom(WBNB, swapHelper, administrationWallet, amountToSend);
    }
    if (marketingAmount > 0) {
      uint amountToSend = (amountOut * marketingAmount) / (totalAmount);
      _tokenTransferFrom(WBNB, swapHelper, marketingWallet, amountToSend);
    }

    accumulatedToPool = 0;
    accumulatedToAdmin = 0;
    accumulatedToMarketing = 0;
  }

  function _splitFee(
    uint incomingFeeAmount,
    address sender,
    uint adminFee,
    uint poolFee,
    uint burnFee,
    uint marketingFee
  ) private {
    uint totalFee = adminFee + poolFee + burnFee + marketingFee;

    //Burn
    if (burnFee > 0) {
      uint burnAmount = (incomingFeeAmount * burnFee) / totalFee;
      _balances[address(this)] += burnAmount;
      _burn(address(this), burnAmount);
    }

    // Administrative distribution
    if (adminFee > 0) {
      accumulatedToAdmin += (incomingFeeAmount * adminFee) / totalFee;
      if (disableAdminFeeSwap) {
        address wallet = administrationWallet;
        _balances[wallet] += accumulatedToAdmin;
        emit Transfer(sender, wallet, accumulatedToAdmin);
        accumulatedToAdmin = 0;
      }
    }

    // Marketing distribution
    if (marketingFee > 0) {
      accumulatedToMarketing += (incomingFeeAmount * marketingFee) / totalFee;
      if (disableMarketingFeeSwap) {
        address wallet = marketingWallet;
        _balances[wallet] += accumulatedToMarketing;
        emit Transfer(sender, wallet, accumulatedToMarketing);
        accumulatedToMarketing = 0;
      }
    }

    // Pool Distribution
    if (poolFee > 0) {
      accumulatedToPool += (incomingFeeAmount * poolFee) / totalFee;
      if (disablePoolFeeSwap) {
        _balances[address(this)] += accumulatedToPool;
        emit Transfer(sender, address(this), accumulatedToPool);
        accumulatedToPool = 0;
      }
    }
  }
}