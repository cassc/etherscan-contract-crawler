pragma solidity 0.5.17;

import "./CompoundOrder.sol";

contract ShortCEtherOrder is CompoundOrder {
  modifier isValidPrice(uint256 _minPrice, uint256 _maxPrice) {
    // Ensure token's price is between _minPrice and _maxPrice
    uint256 tokenPrice = ORACLE.getUnderlyingPrice(compoundTokenAddr); // Get the shorting token's price in USD
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
    
    // Enter Compound markets
    CEther market = CEther(compoundTokenAddr);
    address[] memory markets = new address[](2);
    markets[0] = compoundTokenAddr;
    markets[1] = address(CUSDC);
    uint[] memory errors = COMPTROLLER.enterMarkets(markets);
    require(errors[0] == 0 && errors[1] == 0);

    // Get loan from Compound in tokenAddr
    uint256 loanAmountInToken = __usdcToToken(compoundTokenAddr, loanAmountInUSDC);
    usdc.safeApprove(address(CUSDC), 0); // Clear USDC allowance of Compound USDC market
    usdc.safeApprove(address(CUSDC), collateralAmountInUSDC); // Approve USDC transfer to Compound USDC market
    require(CUSDC.mint(collateralAmountInUSDC) == 0); // Transfer USDC into Compound as supply
    usdc.safeApprove(address(CUSDC), 0);
    require(market.borrow(loanAmountInToken) == 0);// Take out loan
    (bool negLiquidity, ) = getCurrentLiquidityInUSDC();
    require(!negLiquidity); // Ensure account liquidity is positive

    // Convert loaned tokens to USDC
    (uint256 actualUSDCAmount,) = __sellTokenForUSDC(loanAmountInToken);
    loanAmountInUSDC = actualUSDCAmount; // Change loan amount to actual USDC received

    // Repay leftover tokens to avoid complications
    if (address(this).balance > 0) {
      uint256 repayAmount = address(this).balance;
      market.repayBorrow.value(repayAmount)();
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
    for (uint256 i = 0; i < MAX_REPAY_STEPS; i = i++) {
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
        uint256 errorCode = CUSDC.redeemUnderlying(liquidity.mul(PRECISION.sub(DEFAULT_LIQUIDITY_SLIPPAGE)).div(PRECISION));
        if (errorCode != 0) {
          // error
          // try again with fallback slippage
          errorCode = CUSDC.redeemUnderlying(liquidity.mul(PRECISION.sub(FALLBACK_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          if (errorCode != 0) {
            // error
            // try again with max slippage
            CUSDC.redeemUnderlying(liquidity.mul(PRECISION.sub(MAX_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          }
        }
      }

      if (currentDebt <= NEGLIGIBLE_DEBT) {
        break;
      }
    }

    // Send USDC back to PeakDeFiFund and return
    _inputAmount = collateralAmountInUSDC;
    _outputAmount = usdc.balanceOf(address(this));
    outputAmount = _outputAmount;
    usdc.safeTransfer(owner(), usdc.balanceOf(address(this)));
  }

  // Allows manager to repay loan to avoid liquidation
  function repayLoan(uint256 _repayAmountInUSDC) public onlyOwner {
    require(buyTime > 0); // Ensure the order has been executed

    // Convert USDC to shorting token
    (,uint256 actualTokenAmount) = __sellUSDCForToken(_repayAmountInUSDC);

    // Check if amount is greater than borrow balance
    CEther market = CEther(compoundTokenAddr);
    uint256 currentDebt = market.borrowBalanceCurrent(address(this));
    if (actualTokenAmount > currentDebt) {
      actualTokenAmount = currentDebt;
    }

    // Repay loan to Compound
    market.repayBorrow.value(actualTokenAmount)();
  }

  function getMarketCollateralFactor() public view returns (uint256) {
    (, uint256 ratio) = COMPTROLLER.markets(address(CUSDC));
    return ratio;
  }

  function getCurrentCollateralInUSDC() public returns (uint256 _amount) {
    uint256 supply = CUSDC.balanceOf(address(this)).mul(CUSDC.exchangeRateCurrent()).div(PRECISION);
    return supply;
  }

  function getCurrentBorrowInUSDC() public returns (uint256 _amount) {
    CEther market = CEther(compoundTokenAddr);
    uint256 borrow = __tokenToUSDC(compoundTokenAddr, market.borrowBalanceCurrent(address(this)));
    return borrow;
  }

  function getCurrentCashInUSDC() public view returns (uint256 _amount) {
    uint256 cash = getBalance(usdc, address(this));
    return cash;
  }
}