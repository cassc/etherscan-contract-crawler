// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FarmAI is ERC20, Ownable {
  /// General settings
  uint constant public TOTAL_SUPPLY = 1_000_000 ether;
  // Governance
  IUniswapV2Router02 public uniswapRouter;
  // Fees
  uint16 constant FEE_DIVISOR = 10_000;
  struct Fees{
    uint16 buyTeam;  uint16 buyAutoLiquidity;  uint16 buyTotal;
    uint16 sellTeam; uint16 sellAutoLiquidity; uint16 sellTotal;
    uint64 takeFeesTimestamp;
  }
  Fees public fees;
  address public teamWallet;
  address public liquidityWallet;
  mapping(address => bool) public takeFees;
  mapping(address => bool) public ignoreFees;
  mapping(address => uint16) public extraFeeOnEarlySell;
  // Swapping
  struct LiquidationSettings {
    uint128 liquidationThreshold; uint16 percentageToLiquidate;
    bool inLiquidation; bool liquidationEnabled;
  }
  LiquidationSettings public liquidationSettings;
  // Trading
  bool public tradingEnabled;
  mapping(address => bool) public tradingWhiteList;
  
  modifier canTrade(address from, address to){
    require(tradingEnabled || tradingWhiteList[from] || tradingWhiteList[to], "FAI: Trading has not started");
    _;
  }


  constructor(address uniswapRouterAddress) ERC20("FarmAI Token", "FAI") {
    fees = Fees(300, 200, 500, 300, 200, 500, 0);
    liquidationSettings = LiquidationSettings(100 ether, 10_000, false, true);
    teamWallet = liquidityWallet = msg.sender;
    // FAI pair.
    uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
    // Super powers for deployer.
    tradingWhiteList[msg.sender] = true;
    ignoreFees[msg.sender] = true;
    ignoreFees[address(this)] = true;

    _approve(address(this), uniswapRouterAddress, ~uint(0));
    _mint(msg.sender, TOTAL_SUPPLY);
  }

  function _transfer(address from, address to, uint256 amount) internal virtual override canTrade(from, to) {
    uint256 remainingTokens = _takeFees(from, to, amount);
    super._transfer(from, to, remainingTokens);
  }

  function _takeFees(address from, address to, uint256 transferAmount) private returns(uint256 remainingTokens) {
    // Skip certain wallets.
    if(ignoreFees[from] || ignoreFees[to]) return transferAmount;
    // Take fees.
    Fees memory transferFees = fees;
    uint feesToTake = 0;
    // Buy.
    if(takeFees[from]){
      feesToTake += transferAmount * transferFees.buyTotal / FEE_DIVISOR;
      // Early buyers pay an additional fee if they sell within 24h.
      // Helps against sniper bots and stabilizes prices.
      // Within 5min of start:  Extra 25% on sell.
      // Within 15min of start: Extra 15% on sell.
      // Within 30min of start: Extra 10% on sell.
      uint secondsPassedSinceStart = block.timestamp - transferFees.takeFeesTimestamp;
      if(secondsPassedSinceStart <= 30 minutes && extraFeeOnEarlySell[to] == 0){
        if(secondsPassedSinceStart <= 5 minutes)
          extraFeeOnEarlySell[to] = 2_500;
        else if(secondsPassedSinceStart <= 15 minutes)
          extraFeeOnEarlySell[to] = 1_500;
        else
          extraFeeOnEarlySell[to] = 1_000;
      }
    }
    // Sell
    if(takeFees[to]){
      feesToTake += transferAmount * transferFees.sellTotal / FEE_DIVISOR;
      // Now if people sell within the first 24h of token launch they may be paying extra fees. After that: No extra fees.
      if(block.timestamp - transferFees.takeFeesTimestamp <= 24 hours) {
        feesToTake += transferAmount * extraFeeOnEarlySell[from] / FEE_DIVISOR;
      }
    }
    super._transfer(from, address(this), feesToTake);
    // Check if we want to liquidate fees.
    LiquidationSettings memory liqSettings = liquidationSettings;
    if(!takeFees[from] && !liqSettings.inLiquidation && liqSettings.liquidationEnabled){
      uint contractBalance = balanceOf(address(this));
      if(contractBalance >= liqSettings.liquidationThreshold){
        liquidationSettings.inLiquidation = true;
        _liquidateFees(contractBalance, transferFees, liqSettings);
        liquidationSettings.inLiquidation = false;
      }
    }

    remainingTokens = transferAmount - feesToTake;
  }

  function _liquidateFees(uint tokensForLiquidation, Fees memory transferFees, LiquidationSettings memory liqSettings) private {
    // First decide how many tokens to keep as plain tokens and send them to the team wallet.
    uint teamTokens = tokensForLiquidation * ((transferFees.buyTeam + transferFees.sellTeam)) / (transferFees.buyTotal + transferFees.sellTotal);
    uint teamTokensToLiquidate = teamTokens * liqSettings.percentageToLiquidate / FEE_DIVISOR;
    uint teamTokensToKeep = teamTokens - teamTokensToLiquidate;
    super._transfer(address(this), teamWallet, teamTokensToKeep);
    // Now calculate auto-liquidity tokens.
    uint autoLiquidityTokens = tokensForLiquidation * ((transferFees.buyAutoLiquidity + transferFees.sellAutoLiquidity)) / (transferFees.buyTotal + transferFees.sellTotal);
    uint autoLiquidityTokensToLiquidate = autoLiquidityTokens / 2;
    // We only want to liquidate once so we liquidate the team funds tokens and the auto-liquidity tokens all at once.
    // After that we can split the total ETH gained between the two and supply each receiver accordingly.
    uint ethBefore = address(this).balance;
    _liquidateTokens(teamTokensToLiquidate + autoLiquidityTokensToLiquidate, address(this));
    uint ethGained = address(this).balance - ethBefore;
    // Send team funds.
    uint ethForTeam = ethGained * teamTokensToLiquidate / (teamTokensToLiquidate + autoLiquidityTokensToLiquidate);
    payable(teamWallet).transfer(ethForTeam);
    // Auto-liquidity
    _autoLiquidity(autoLiquidityTokensToLiquidate, ethGained - ethForTeam, liquidityWallet);
  }

  function _liquidateTokens(uint tokenAmount, address to) private {
    address[] memory path = new address[](2); path[0] = address(this); path[1] = uniswapRouter.WETH();
    uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount, 0, path,
      to, block.timestamp
    );
  }

  function _autoLiquidity(uint faiTokens, uint eth, address liquidityTokenReceiver) private {
    uniswapRouter.addLiquidityETH{value: eth}(
      address(this),
      faiTokens,
      0, 0,
      liquidityTokenReceiver,
      block.timestamp
    );
  }

  // Utility functions.
  // Recovery
  function recoverERC20(address token, uint balance) external onlyOwner {
    IERC20(token).transfer(owner(), balance);
  }
  function recoverETH(uint balance) external onlyOwner {
    payable(owner()).transfer(balance);
  }
  // Fees
  function setFees(
    uint16 buyTeam, uint16 buyAutoLiquidity,
    uint16 sellTeam, uint16 sellAutoLiquidity
    ) external onlyOwner {
      // Maximum of 30% each.
      uint16 buyTotal = buyTeam + buyAutoLiquidity;
      uint16 sellTotal = sellTeam + sellAutoLiquidity;
      require(buyTotal <= 3_000 && sellTotal <= 3_000, "FAI: TAXES_TOO_HIGH");

      fees = Fees(buyTeam, buyAutoLiquidity, buyTotal, sellTeam, sellAutoLiquidity, sellTotal, fees.takeFeesTimestamp);
    }
  // Set who should be taxed in general.
  function setTakeFeeFor(address target, bool takeFee) external onlyOwner {
    takeFees[target] = takeFee;
  }
  // Set who should be ignored from taxes. This is stronger than `takeFees`.
  function setIgnoreFees(address target, bool ignoreFee) external onlyOwner {
    ignoreFees[target] = ignoreFee;
  }
  // Update wallets.
  function setTeamWallet(address _teamWallet) external onlyOwner {
    require(teamWallet != address(0), "FAI: INVALID_FEE_WALLET");
    teamWallet = _teamWallet;
  }
  function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
    require(teamWallet != address(0), "FAI: INVALID_FEE_WALLET");
    liquidityWallet = _liquidityWallet;
  }
  // Update liquidation settings.
  function setLiquidationSettings(uint128 liquidationThreshold, uint16 percentageToLiquidate, bool liquidationEnabled) external onlyOwner {
    require(liquidationThreshold <= TOTAL_SUPPLY && percentageToLiquidate <= 10_000, "FAI: INVALID_LIQ_SET");
    liquidationSettings = LiquidationSettings(liquidationThreshold, percentageToLiquidate, false, liquidationEnabled);
  }
  // Trading
  function startTrading() external onlyOwner { 
    require(tradingEnabled == false, "FAI: ALREADY_STARTED");
    tradingEnabled = true; 
    fees.takeFeesTimestamp = uint64(block.timestamp); 
  }
  function whiteListTrade(address target, bool _canTrade) external onlyOwner {
    tradingWhiteList[target] = _canTrade;
  }

  receive() external payable { }
}