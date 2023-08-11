// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

contract CryptoVoucherToken is ERC20, Ownable {
  /// General settings
  uint constant public TOTAL_SUPPLY = 10_000_000 ether;
  // Governance
  IUniswapV2Router02 public uniswapRouter;
  // Fees
  uint16 constant FEE_DIVISOR = 10_000;
  struct Fees{
    uint128 liquidationThreshold;
    bool liquidationEnabled;
    uint16 buyTeam;  uint16 buyAutoLiquidity;  uint16 buyTotal;
    uint16 sellTeam; uint16 sellAutoLiquidity; uint16 sellTotal;
  }
  
  Fees public fees;
  address public teamWallet;
  address public liquidityWallet;
  mapping(address => bool) public takeFees;
  mapping(address => bool) public ignoreFees;
  // Trading
  bool public tradingEnabled;
  mapping(address => bool) public tradingWhiteList;
  
  modifier canTrade(address from, address to){
    require(tradingEnabled || tradingWhiteList[from] || tradingWhiteList[to], "CVT: Trading has not started");
    _;
  }
  bool isLiquidating;

  constructor(address uniswapRouterAddress) ERC20("CryptoVoucherToken Token", "CVT") {
    fees = Fees(10_000 ether, true, 400, 100, 500, 400, 100, 500);
    teamWallet = liquidityWallet = msg.sender;
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
    if(takeFees[from]){ feesToTake += transferAmount * transferFees.buyTotal / FEE_DIVISOR; }
    // Sell
    if(takeFees[to]){ feesToTake += transferAmount * transferFees.sellTotal / FEE_DIVISOR; }
    super._transfer(from, address(this), feesToTake);
    // Check if we want to liquidate fees.
    if(!takeFees[from] && !isLiquidating && fees.liquidationEnabled){
      uint contractBalance = balanceOf(address(this));
      if(contractBalance >= uint(fees.liquidationThreshold)){
        isLiquidating = true;
        _liquidateFees(contractBalance, transferFees);
        isLiquidating = false;
      }
    }
    remainingTokens = transferAmount - feesToTake;
  }

  function _liquidateFees(uint tokensForLiquidation, Fees memory transferFees) private {
    // For auto liquidity, liquidate half tokens and put in the remaining ones for liquidity.
    uint autoLiquidityTokens = tokensForLiquidation * ((transferFees.buyAutoLiquidity + transferFees.sellAutoLiquidity)) / (transferFees.buyTotal + transferFees.sellTotal);
    uint autoLiquidityTokensToLiquidate = autoLiquidityTokens / 2;
    // Team tokens are all tokens left.
    uint teamTokens = tokensForLiquidation - autoLiquidityTokens;
    // Liquidate tokens.
    uint ethBefore = address(this).balance;
    _liquidateTokens(teamTokens + autoLiquidityTokensToLiquidate, address(this));
    uint ethGained = address(this).balance - ethBefore;
    // Send team funds.
    uint ethForTeam = ethGained * teamTokens / (teamTokens + autoLiquidityTokensToLiquidate);
    (bool success,) = payable(teamWallet).call{value: ethForTeam}("");
    require(success, "CVT: LIQ_FAILED");
    // Auto-liquidity
    if(autoLiquidityTokensToLiquidate > 0)
      _autoLiquidity(autoLiquidityTokensToLiquidate, ethGained - ethForTeam, liquidityWallet);
  }

  function _liquidateTokens(uint tokenAmount, address to) private {
    address[] memory path = new address[](2); path[0] = address(this); path[1] = uniswapRouter.WETH();
    uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount, 0, path,
      to, block.timestamp
    );
  }

  function _autoLiquidity(uint croTokens, uint eth, address liquidityTokenReceiver) private {
    uniswapRouter.addLiquidityETH{value: eth}(
      address(this),
      croTokens,
      0, 0,
      liquidityTokenReceiver,
      block.timestamp
    );
  }

  // Utility functions.
  // Recovery
  function recoverERC20(address token, uint balance) external onlyOwner {
    // Don't recover CVT tokens. Safety for holders.
    require(token != address(this), "CVT: INVALID_RECOVER");
    IERC20(token).transfer(owner(), balance);
  }
  function recoverETH(uint balance) external onlyOwner {
    payable(owner()).transfer(balance);
  }
  // Fees
  function setFees(
    uint128 liquidationThreshold, bool liquidationEnabled,
    uint16 buyTeam, uint16 buyAutoLiquidity,
    uint16 sellTeam, uint16 sellAutoLiquidity
    ) external onlyOwner {
      // Maximum of 15% each.
      uint16 buyTotal = buyTeam + buyAutoLiquidity;
      uint16 sellTotal = sellTeam + sellAutoLiquidity;
      require(buyTotal <= 1_500 && sellTotal <= 1_500, "CVT: TAXES_TOO_HIGH");

      fees = Fees(liquidationThreshold, liquidationEnabled, buyTeam, buyAutoLiquidity, buyTotal, sellTeam, sellAutoLiquidity, sellTotal);
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
    require(teamWallet != address(0), "CVT: INVALID_FEE_WALLET");
    teamWallet = _teamWallet;
  }
  function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
    require(teamWallet != address(0), "CVT: INVALID_FEE_WALLET");
    liquidityWallet = _liquidityWallet;
  }
  // Trading
  function startTrading() external onlyOwner { 
    require(tradingEnabled == false, "CVT: ALREADY_STARTED");
    tradingEnabled = true;
  }
  function whiteListTrade(address target, bool _canTrade) external onlyOwner {
    tradingWhiteList[target] = _canTrade;
  }

  receive() external payable { }
}