// SPDX-License-Identifier: PROPRIETARY - Lameni

pragma solidity 0.8.16;

import "./ERC20.sol";
import "./IPancake.sol";
import "./GasHelper.sol";
import "./SwapHelper.sol";

contract RunnerLandTokenV2 is GasHelper, ERC20 {
  address constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address constant ZERO = 0x0000000000000000000000000000000000000000;
  address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // BSC WBNB
  address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

  string constant _name = "RunnerLand V2";
  string constant _symbol = "RLTv2";

  string public constant url = "www.runner.land";

  uint constant maxSupply = 1_000_000_000e18;

  // Wallets limits
  uint public _maxTxAmount = maxSupply;
  uint public _maxAccountAmount = maxSupply;
  uint public _minAmountToAutoSwap = 1000 * (10**decimals()); // 100

  // Fees
  uint public feePool = 0;
  uint public feeReflect = 0;
  uint public feeBurnRate = 0;
  uint public feeAdministrationWallet = 0;
  uint public feeMarketingWallet = 0;

  uint constant maxTotalFee = 500;

  mapping(address => uint) public specialFeesByWallet;
  mapping(address => uint) public specialFeesByWalletReceiver;

  // Helpers
  bool internal pausedToken;
  bool private _noReentrance;

  bool public pausedSwapPool;
  bool public pausedSwapAdmin;
  bool public pausedSwapMarketing;
  bool public disabledReflect = true;
  bool public disabledAutoLiquidity = true;

  // Counters
  uint public totalBurned;
  uint public accumulatedToReflect;
  uint public accumulatedToAdmin;
  uint public accumulatedToMarketing;
  uint public accumulatedToPool;

  // Liquidity Pair
  address public liquidityPool;

  // Wallets
  address public administrationWallet;
  address public marketingWallet;

  address public swapHelperAddress;

  // Reflect VARIABLES
  mapping(address => HolderShare) public holderMap;

  uint private constant reflectPrecision = 10**18;
  uint private reflectPerShare;

  uint public minTokenHoldToReflect = 100 * (10**decimals()); // min holder must have to be able to receive reflect
  uint public totalTokens;

  struct HolderShare {
    uint amountToken;
    uint totalReceived;
    uint entryPointMarkup;
  }

  receive() external payable {}

  constructor() ERC20(_name, _symbol) {
    permissions[0][_msgSender()] = true;
    permissions[1][_msgSender()] = true;
    permissions[2][_msgSender()] = true;
    permissions[3][_msgSender()] = true;

    PancakeRouter router = PancakeRouter(PANCAKE_ROUTER);
    liquidityPool = address(PancakeFactory(router.factory()).createPair(WBNB, address(this)));

    uint baseAttributes = 0;
    baseAttributes = setExemptAmountLimit(baseAttributes, true);
    baseAttributes = setExemptReflect(baseAttributes, true);
    _attributeMap[liquidityPool] = baseAttributes;

    baseAttributes = setExemptTxLimit(baseAttributes, true);
    _attributeMap[DEAD] = baseAttributes;
    _attributeMap[ZERO] = baseAttributes;

    baseAttributes = setExemptFee(baseAttributes, true);
    _attributeMap[address(this)] = baseAttributes;

    baseAttributes = setExemptOperatePausedToken(baseAttributes, true);
    baseAttributes = setExemptSwapperMaker(baseAttributes, true);
    baseAttributes = setExemptFeeReceiver(baseAttributes, true);

    _attributeMap[_msgSender()] = baseAttributes;

    SwapHelper swapHelper = new SwapHelper();
    swapHelper.safeApprove(WBNB, address(this), type(uint).max);
    swapHelper.transferOwnership(_msgSender());
    swapHelperAddress = address(swapHelper);

    baseAttributes = setExemptOperatePausedToken(baseAttributes, false);
    _attributeMap[swapHelperAddress] = baseAttributes;

    _mint(_msgSender(), maxSupply);

    pausedToken = true;

    administrationWallet = _msgSender();
    marketingWallet = _msgSender();
  }

  // ----------------- Public Views -----------------
  function getOwner() external view returns (address) {
    return owner();
  }

  function getFeeTotal() public view returns (uint) {
    return feePool + feeReflect + feeBurnRate + feeAdministrationWallet + feeMarketingWallet;
  }

  function getSpecialWalletFee(address target, bool isSender)
    public
    view
    returns (
      uint reflect,
      uint pool,
      uint burnRate,
      uint adminFee,
      uint marketingFee
    )
  {
    uint composedValue = isSender ? specialFeesByWallet[target] : specialFeesByWalletReceiver[target];
    reflect = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    pool = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    burnRate = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    adminFee = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    marketingFee = composedValue % 1e4;
  }

  function balanceOf(address account) public view override returns (uint) {
    uint entryPointMarkup = holderMap[account].entryPointMarkup;
    uint totalToBePaid = (holderMap[account].amountToken * reflectPerShare) / reflectPrecision;
    return _balances[account] + (totalToBePaid <= entryPointMarkup ? 0 : totalToBePaid - entryPointMarkup);
  }

  // ----------------- Authorized Methods -----------------

  function enableToken() external isAuthorized(0) {
    pausedToken = false;
  }

  function setLiquidityPool(address newPair) external isAuthorized(0) {
    require(newPair != ZERO, "Invalid address");
    liquidityPool = newPair;
  }

  function setPausedSwapPool(bool state) external isAuthorized(0) {
    pausedSwapPool = state;
  }

  function setPausedSwapAdmin(bool state) external isAuthorized(0) {
    pausedSwapAdmin = state;
  }

  function setPausedSwapMarketing(bool state) external isAuthorized(0) {
    pausedSwapMarketing = state;
  }

  function setDisabledReflect(bool state) external isAuthorized(0) {
    disabledReflect = state;
  }

  function setDisabledAutoLiquidity(bool state) external isAuthorized(0) {
    disabledAutoLiquidity = state;
  }

  // ----------------- Wallets Settings -----------------
  function setAdministrationWallet(address account) public isAuthorized(0) {
    administrationWallet = account;
  }

  function setMarketingWallet(address account) public isAuthorized(0) {
    marketingWallet = account;
  }

  // ----------------- Fee Settings -----------------
  function setFees(
    uint reflect,
    uint pool,
    uint burnRate,
    uint administration,
    uint feeMarketing
  ) external isAuthorized(1) {
    feePool = pool;
    feeReflect = reflect;
    feeBurnRate = burnRate;
    feeAdministrationWallet = administration;
    feeMarketingWallet = feeMarketing;
    require(getFeeTotal() <= maxTotalFee, "All fee together must be lower than 5%");
  }

  function setSpecialWalletFeeOnSend(
    address target,
    uint reflect,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) public isAuthorized(1) {
    setSpecialWalletFee(target, true, reflect, pool, burnRate, adminFee, marketingFee);
  }

  function setSpecialWalletFeeOnReceive(
    address target,
    uint reflect,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) public isAuthorized(1) {
    setSpecialWalletFee(target, false, reflect, pool, burnRate, adminFee, marketingFee);
  }

  function setSpecialWalletFee(
    address target,
    bool isSender,
    uint reflect,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) private {
    uint total = reflect + pool + burnRate + adminFee + marketingFee;
    require(total <= maxTotalFee, "All rates and fee together must be lower than 5%");
    uint composedValue = reflect + (pool * 1e4) + (burnRate * 1e8) + (adminFee * 1e12) + (marketingFee * 1e16);
    if (isSender) {
      specialFeesByWallet[target] = composedValue;
    } else {
      specialFeesByWalletReceiver[target] = composedValue;
    }
  }

  // ----------------- Token Flow Settings -----------------
  function setMaxTxAmount(uint maxTxAmount) public isAuthorized(1) {
    require(maxTxAmount >= maxSupply / 100_000, "Amount must be bigger then 0.001% tokens");
    _maxTxAmount = maxTxAmount;
  }

  function setMaxAccountAmount(uint maxAccountAmount) public isAuthorized(1) {
    require(maxAccountAmount >= maxSupply / 100_000, "Amount must be bigger then 0.001% tokens");
    _maxAccountAmount = maxAccountAmount;
  }

  function setMinAmountToAutoSwap(uint amount) public isAuthorized(1) {
    _minAmountToAutoSwap = amount;
  }

  struct Receivers {
    address wallet;
    uint amount;
  }

  function multiSend(Receivers[] memory users) external {
    for (uint i = 0; i < users.length; i++) transfer(users[i].wallet, users[i].amount);
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
    require(!pausedToken || isExemptOperatePausedToken(senderAttributes), "Token is paused");
    require(amount <= _maxTxAmount || isExemptTxLimit(senderAttributes), "Exceeded the maximum transaction limit");

    // Update Sender Balance to add pending staking
    if (!isExemptReflect(senderAttributes) && !disabledReflect) _updateHolder(sender, _balances[sender], minTokenHoldToReflect, reflectPerShare);
    uint senderBalance = _balances[sender];
    require(senderBalance >= amount, "Transfer amount exceeds your balance");
    senderBalance -= amount;
    _balances[sender] = senderBalance;

    uint adminFee;
    uint poolFee;
    uint burnFee;
    uint marketingFee;
    uint reflectFee;

    // Calculate Fees
    uint feeAmount = 0;
    if (!isExemptFee(senderAttributes) && !isExemptFeeReceiver(receiverAttributes)) {
      if (isSpecialFeeWallet(senderAttributes)) {
        (reflectFee, poolFee, burnFee, adminFee, marketingFee) = getSpecialWalletFee(sender, true); // Check special wallet fee on sender
      } else if (isSpecialFeeWalletReceiver(receiverAttributes)) {
        (reflectFee, poolFee, burnFee, adminFee, marketingFee) = getSpecialWalletFee(receiver, true); // Check special wallet fee on receiver
      } else {
        adminFee = feeAdministrationWallet;
        poolFee = feePool;
        burnFee = feeBurnRate;
        marketingFee = feeMarketingWallet;
        reflectFee = feeReflect;
      }
      feeAmount = ((reflectFee + poolFee + burnFee + adminFee + marketingFee) * amount) / 10_000;
    }

    if (feeAmount != 0) splitFee(feeAmount, sender, adminFee, poolFee, burnFee, marketingFee, reflectFee);
    if ((!pausedSwapPool || !pausedSwapAdmin || !pausedSwapMarketing) && !isExemptSwapperMaker(senderAttributes)) autoSwap(sender);

    // Update Recipient Balance
    uint newRecipientBalance = _balances[receiver] + (amount - feeAmount);
    _balances[receiver] = newRecipientBalance;
    require(newRecipientBalance <= _maxAccountAmount || isExemptAmountLimit(receiverAttributes), "Exceeded the maximum tokens an wallet can hold");

    if (!disabledReflect) executeReflectOperations(sender, receiver, senderBalance, newRecipientBalance, senderAttributes, receiverAttributes);

    _noReentrance = false;
    emit Transfer(sender, receiver, amount - feeAmount);
  }

  function operateSwap(
    address liquidityPair,
    address swapHelper,
    uint amountIn
  ) private returns (uint) {
    (uint112 reserve0, uint112 reserve1) = getTokenReserves(liquidityPair);
    bool reversed = isReversed(liquidityPair, WBNB);

    if (reversed) {
      uint112 temp = reserve0;
      reserve0 = reserve1;
      reserve1 = temp;
    }

    _balances[liquidityPair] += amountIn;
    uint wbnbAmount = getAmountOut(amountIn, reserve1, reserve0);
    if (!reversed) {
      swapToken(liquidityPair, wbnbAmount, 0, swapHelper);
    } else {
      swapToken(liquidityPair, 0, wbnbAmount, swapHelper);
    }
    return wbnbAmount;
  }

  function autoSwap(address sender) private {
    // --------------------- Execute Auto Swap -------------------------
    address liquidityPair = liquidityPool;
    address swapHelper = swapHelperAddress;

    if (sender == liquidityPair) return;

    uint poolAmount = accumulatedToPool / 2;
    uint adminAmount = accumulatedToAdmin;
    uint marketingAmount = accumulatedToMarketing;
    uint totalAmount = poolAmount + adminAmount + marketingAmount;

    if (totalAmount < _minAmountToAutoSwap) return;

    // Execute auto swap
    uint amountOut = operateSwap(liquidityPair, swapHelper, totalAmount);

    // --------------------- Add Liquidity -------------------------
    if (poolAmount > 0) {
      if (!disabledAutoLiquidity) {
        uint amountToSend = (amountOut * poolAmount) / (totalAmount);
        (uint112 reserve0, uint112 reserve1) = getTokenReserves(liquidityPair);
        bool reversed = isReversed(liquidityPair, WBNB);
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
        tokenTransferFrom(WBNB, swapHelper, liquidityPair, amountA);
        _balances[liquidityPair] += amountB;
        IPancakePair(liquidityPair).mint(address(this));
      }
    }

    // --------------------- Transfer Swapped Amount -------------------------
    if (adminAmount > 0) {
      uint amountToSend = (amountOut * adminAmount) / (totalAmount);
      tokenTransferFrom(WBNB, swapHelper, administrationWallet, amountToSend);
    }
    if (marketingAmount > 0) {
      uint amountToSend = (amountOut * marketingAmount) / (totalAmount);
      tokenTransferFrom(WBNB, swapHelper, marketingWallet, amountToSend);
    }

    accumulatedToPool = 0;
    accumulatedToAdmin = 0;
    accumulatedToMarketing = 0;
  }

  function splitFee(
    uint incomingFeeAmount,
    address sender,
    uint adminFee,
    uint poolFee,
    uint burnFee,
    uint marketingFee,
    uint reflectFee
  ) private {
    uint totalFee = adminFee + poolFee + burnFee + marketingFee + reflectFee;

    //Burn
    if (burnFee > 0) {
      uint burnAmount = (incomingFeeAmount * burnFee) / totalFee;
      _balances[address(this)] += burnAmount;
      _burn(address(this), burnAmount);
    }

    if (reflectFee > 0) {
      accumulatedToReflect += (incomingFeeAmount * reflectFee) / totalFee;
    }

    // Administrative distribution
    if (adminFee > 0) {
      accumulatedToAdmin += (incomingFeeAmount * adminFee) / totalFee;
      if (pausedSwapAdmin) {
        address wallet = administrationWallet;
        uint walletBalance = _balances[wallet] + accumulatedToAdmin;
        _balances[wallet] = walletBalance;
        if (!isExemptReflect(_attributeMap[wallet]) && !disabledReflect) _updateHolder(wallet, walletBalance, minTokenHoldToReflect, reflectPerShare);
        emit Transfer(sender, wallet, accumulatedToAdmin);
        accumulatedToAdmin = 0;
      }
    }

    // Marketing distribution
    if (marketingFee > 0) {
      accumulatedToMarketing += (incomingFeeAmount * marketingFee) / totalFee;
      if (pausedSwapMarketing) {
        address wallet = marketingWallet;
        uint walletBalance = _balances[wallet] + accumulatedToMarketing;
        _balances[wallet] = walletBalance;
        if (!isExemptReflect(_attributeMap[wallet]) && !disabledReflect) _updateHolder(wallet, walletBalance, minTokenHoldToReflect, reflectPerShare);
        emit Transfer(sender, wallet, accumulatedToMarketing);
        accumulatedToMarketing = 0;
      }
    }

    // Pool Distribution
    if (poolFee > 0) {
      accumulatedToPool += (incomingFeeAmount * poolFee) / totalFee;
      if (pausedSwapPool) {
        _balances[address(this)] += accumulatedToPool;
        emit Transfer(sender, address(this), accumulatedToPool);
        accumulatedToPool = 0;
      }
    }
  }

  // --------------------- Reflect Internal Methods -------------------------

  function setMinTokenHoldToReflect(uint amount) external isAuthorized(1) {
    minTokenHoldToReflect = amount;
  }

  function executeReflectOperations(
    address sender,
    address receiver,
    uint senderAmount,
    uint receiverAmount,
    uint senderAttributes,
    uint receiverAttributes
  ) private {
    uint minTokenHolder = minTokenHoldToReflect;
    uint reflectPerShareValue = reflectPerShare;

    if (!isExemptReflect(senderAttributes)) _updateHolder(sender, senderAmount, minTokenHolder, reflectPerShareValue);

    // Calculate new reflect per share value
    uint accumulated = accumulatedToReflect;
    if (accumulated > 0) {
      uint consideredTotalTokens = totalTokens;
      reflectPerShareValue += (accumulated * reflectPrecision) / (consideredTotalTokens == 0 ? 1 : consideredTotalTokens);
      reflectPerShare = reflectPerShareValue;
      accumulatedToReflect = 0;
    }

    if (!isExemptReflect(receiverAttributes)) _updateHolder(receiver, receiverAmount, minTokenHolder, reflectPerShareValue);
  }

  function _updateHolder(
    address holder,
    uint amount,
    uint minTokenHolder,
    uint reflectPerShareValue
  ) private {
    // If holder has less than minTokenHoldToReflect, then does not participate on staking
    uint consideredAmount = minTokenHolder <= amount ? amount : 0;
    uint holderAmount = holderMap[holder].amountToken;

    if (holderAmount > 0) {
      uint entryPointMarkup = holderMap[holder].entryPointMarkup;
      uint totalToBePaid = (holderAmount * reflectPerShareValue) / reflectPrecision;
      if (totalToBePaid > entryPointMarkup) {
        uint toReceive = totalToBePaid - entryPointMarkup;
        _balances[holder] += toReceive;
        holderMap[holder].totalReceived += toReceive;
      }
    }

    totalTokens = (totalTokens - holderAmount) + consideredAmount;
    holderMap[holder].amountToken = consideredAmount;
    holderMap[holder].entryPointMarkup = (consideredAmount * reflectPerShareValue) / reflectPrecision;
  }
}