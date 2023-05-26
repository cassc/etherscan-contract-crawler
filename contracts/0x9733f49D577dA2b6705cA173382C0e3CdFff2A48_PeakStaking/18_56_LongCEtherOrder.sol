pragma solidity 0.5.17;

import "./CompoundOrder.sol";

contract LongCEtherOrder is CompoundOrder {
  modifier isValidPrice(uint256 _minPrice, uint256 _maxPrice) {
    // Ensure token's price is between _minPrice and _maxPrice
    uint256 tokenPrice = ORACLE.getUnderlyingPrice(compoundTokenAddr); // Get the longing token's price in USD
    require(tokenPrice > 0); // Ensure asset exists on Compound
    require(tokenPrice >= _minPrice && tokenPrice <= _maxPrice); // Ensure price is within range
    _;
  }

  function executeOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidToken(compoundTokenAddr)
    isValidPrice(_minPrice, _maxPrice)
  {
    buyTime = now;
    
    // Get funds in USDC from PeakDeFiFund
    usdc.safeTransferFrom(owner(), address(this), collateralAmountInUSDC); // Transfer USDC from PeakDeFiFund

    // Convert received USDC to longing token
    (,uint256 actualTokenAmount) = __sellUSDCForToken(collateralAmountInUSDC);

    // Enter Compound markets
    CEther market = CEther(compoundTokenAddr);
    address[] memory markets = new address[](2);
    markets[0] = compoundTokenAddr;
    markets[1] = address(CUSDC);
    uint[] memory errors = COMPTROLLER.enterMarkets(markets);
    require(errors[0] == 0 && errors[1] == 0);
    
    // Get loan from Compound in USDC
    market.mint.value(actualTokenAmount)(); // Transfer tokens into Compound as supply
    require(CUSDC.borrow(loanAmountInUSDC) == 0);// Take out loan in USDC
    (bool negLiquidity, ) = getCurrentLiquidityInUSDC();
    require(!negLiquidity); // Ensure account liquidity is positive

    // Convert borrowed USDC to longing token
    __sellUSDCForToken(loanAmountInUSDC);

    // Repay leftover USDC to avoid complications
    if (usdc.balanceOf(address(this)) > 0) {
      uint256 repayAmount = usdc.balanceOf(address(this));
      usdc.safeApprove(address(CUSDC), 0);
      usdc.safeApprove(address(CUSDC), repayAmount);
      require(CUSDC.repayBorrow(repayAmount) == 0);
      usdc.safeApprove(address(CUSDC), 0);
    }
  }

  function sellOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidPrice(_minPrice, _maxPrice)
    returns (uint256 _inputAmount, uint256 _outputAmount)
  {
    require(buyTime > 0); // Ensure the order has been executed
    require(isSold == false);
    isSold = true;

    // Siphon remaining collateral by repaying x USDC and getting back 1.5x USDC collateral
    // Repeat to ensure debt is exhausted
    CEther market = CEther(compoundTokenAddr);
    for (uint256 i = 0; i < MAX_REPAY_STEPS; i++) {
      uint256 currentDebt = getCurrentBorrowInUSDC();
      if (currentDebt > NEGLIGIBLE_DEBT) {
        // Determine amount to be repaid this step
        uint256 currentBalance = getCurrentCashInUSDC();
        uint256 repayAmount = 0; // amount to be repaid in USDC
        if (currentDebt <= currentBalance) {
          // Has enough money, repay all debt
          repayAmount = currentDebt;
        } else {
          // Doesn't have enough money, repay whatever we can repay
          repayAmount = currentBalance;
        }

        // Repay debt
        repayLoan(repayAmount);
      }

      // Withdraw all available liquidity
      (bool isNeg, uint256 liquidity) = getCurrentLiquidityInUSDC();
      if (!isNeg) {
        liquidity = __usdcToToken(compoundTokenAddr, liquidity);
        uint256 errorCode = market.redeemUnderlying(liquidity.mul(PRECISION.sub(DEFAULT_LIQUIDITY_SLIPPAGE)).div(PRECISION));
        if (errorCode != 0) {
          // error
          // try again with fallback slippage
          errorCode = market.redeemUnderlying(liquidity.mul(PRECISION.sub(FALLBACK_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          if (errorCode != 0) {
            // error
            // try again with max slippage
            market.redeemUnderlying(liquidity.mul(PRECISION.sub(MAX_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          }
        }
      }

      if (currentDebt <= NEGLIGIBLE_DEBT) {
        break;
      }
    }

    // Sell all longing token to USDC
    __sellTokenForUSDC(address(this).balance);

    // Send USDC back to PeakDeFiFund and return
    _inputAmount = collateralAmountInUSDC;
    _outputAmount = usdc.balanceOf(address(this));
    outputAmount = _outputAmount;
    usdc.safeTransfer(owner(), usdc.balanceOf(address(this)));
    toPayableAddr(owner()).transfer(address(this).balance); // Send back potential leftover tokens
  }

  // Allows manager to repay loan to avoid liquidation
  function repayLoan(uint256 _repayAmountInUSDC) public onlyOwner {
    require(buyTime > 0); // Ensure the order has been executed

    // Convert longing token to USDC
    uint256 repayAmountInToken = __usdcToToken(compoundTokenAddr, _repayAmountInUSDC);
    (uint256 actualUSDCAmount,) = __sellTokenForUSDC(repayAmountInToken);
    
    // Check if amount is greater than borrow balance
    uint256 currentDebt = CUSDC.borrowBalanceCurrent(address(this));
    if (actualUSDCAmount > currentDebt) {
      actualUSDCAmount = currentDebt;
    }

    // Repay loan to Compound
    usdc.safeApprove(address(CUSDC), 0);
    usdc.safeApprove(address(CUSDC), actualUSDCAmount);
    require(CUSDC.repayBorrow(actualUSDCAmount) == 0);
    usdc.safeApprove(address(CUSDC), 0);
  }

  function getMarketCollateralFactor() public view returns (uint256) {
    (, uint256 ratio) = COMPTROLLER.markets(address(compoundTokenAddr));
    return ratio;
  }

  function getCurrentCollateralInUSDC() public returns (uint256 _amount) {
    CEther market = CEther(compoundTokenAddr);
    uint256 supply = __tokenToUSDC(compoundTokenAddr, market.balanceOf(address(this)).mul(market.exchangeRateCurrent()).div(PRECISION));
    return supply;
  }

  function getCurrentBorrowInUSDC() public returns (uint256 _amount) {
    uint256 borrow = CUSDC.borrowBalanceCurrent(address(this));
    return borrow;
  }

  function getCurrentCashInUSDC() public view returns (uint256 _amount) {
    ERC20Detailed token = __underlyingToken(compoundTokenAddr);
    uint256 cash = __tokenToUSDC(compoundTokenAddr, getBalance(token, address(this)));
    return cash;
  }
}