// SPDX-License-Identifier: MIT
/**
 *  Illiquid markets are often unpredictable, but human behavior doesn't typcially change. QuantumAI aims
 *  to use a highly trained LSTM Neural Network [AI] to create trading bots that dynamically tune parameters  
 *  in real-time in response to rapidly changing market conditions.
 *
 *  Telegram: https://t.me/QuantumAI_QAI
 *  Twitter: https://twitter.com/QuantumAI_QAI
 *  Homepage: https://quantum-ai.com/
 * 
 *  Total Supply: 100 Million Tokens
 * 
 *  Set slippage to 7%: 6% on buy and sell (3% self-liquidity, 2% treasury and 1% bot operations)
*/

pragma solidity 0.8.17;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./tokens/ERC20.sol";
import "./utils/Ownable.sol";

contract QuantumAI is ERC20, Ownable {
  uint public launchDate;
  address payable public botWallet;
  address payable public treasuryWallet;
  address payable public liqWallet;
  address public immutable uniswapV2Pair;
  IUniswapV2Router02 public immutable uniswapV2Router;
  bool private inSwapAndLiquify;
  bool public launched;
  BuyTax public buyTax;
  SellTax public sellTax;

  uint private _supply = 100000000;
  uint8 private _decimals = 9;
  string private _name = "QuantumAI";
  string private _symbol = "QAI";
  uint public numTokensSellForTax = 500000000000000;
  bool public taxSwap = true;

  struct BuyTax {
    uint16 liquidityTax;
    uint16 botTax;
    uint16 teamTax;
    uint16 burnTax;
    uint16 totalTax;
  }

  struct SellTax {
    uint16 liquidityTax;
    uint16 botTax;
    uint16 teamTax;
    uint16 burnTax;
    uint16 totalTax;
  }

  mapping(address => bool) public excludedFromFee;

  event SwapAndLiquify(uint tokensSwapped, uint ethReceived, uint tokensIntoLiqudity);

  constructor(address payable newBotWallet, address payable newTreasuryWallet, address payable newLiqWallet, address newRouter) ERC20(_name, _symbol) {
    _mint(msg.sender, (_supply * 10 ** _decimals));
    botWallet = newBotWallet;
    treasuryWallet = newTreasuryWallet;
    liqWallet = newLiqWallet;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;

    excludedFromFee[address(_uniswapV2Router)] = true;
    excludedFromFee[msg.sender] = true;
    excludedFromFee[botWallet] = true;
    excludedFromFee[treasuryWallet] = true;
    excludedFromFee[liqWallet] = true;

    buyTax = BuyTax(3, 1, 2, 0, 6);
    sellTax = SellTax(3, 1, 2, 0, 6);
  }

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  receive() external payable {}

  /**
   * @notice Enables initial trading and logs time of activation. Once trading is started it cannot be stopped.
   */
  function launch() external onlyOwner {
    launched = true;
    launchDate = block.timestamp;
  }

  function setBotWallet(address payable _botWallet) external onlyOwner {
    require(_botWallet != address(0), "Address cannot be 0 address");
    botWallet = _botWallet;
  }

  function setTreasuryWallet(address payable _treasuryWallet) external onlyOwner {
    require(_treasuryWallet != address(0), "Address cannot be 0 address");
    treasuryWallet = _treasuryWallet;
  }

  function setLiqWallet(address payable _liqWallet) external onlyOwner {
    require(_liqWallet != address(0), "Address cannot be 0 address");
    liqWallet = _liqWallet;
  }

  function addToWhitelist(address _address) external onlyOwner {
    excludedFromFee[_address] = true;
  }

  function removeFromWhitelist(address _address) external onlyOwner {
    excludedFromFee[_address] = false;
  }

  function setTaxSwap(bool _taxSwap) external onlyOwner {
    taxSwap = _taxSwap;
  }

  function setBuyTax(uint16 liquidityTax, uint16 botTax, uint16 teamTax, uint16 burnTax) external onlyOwner {
    uint16 totalTax = liquidityTax + botTax + teamTax + burnTax;
    require(totalTax <= 10, "ERC20: total tax must not be greater than 10");
    buyTax = BuyTax(liquidityTax, botTax, teamTax, burnTax, totalTax);
  }

  function setSellTax(uint16 liquidityTax, uint16 botTax, uint16 teamTax, uint16 burnTax) external onlyOwner {
    uint16 totalTax = liquidityTax + botTax + teamTax + burnTax;
    require(totalTax <= 10, "ERC20: total tax must not be greater than 10");
    sellTax = SellTax(liquidityTax, botTax, teamTax, burnTax, totalTax);
  }

  function setTokensToSellForTax(uint _numTokensSellForTax) external onlyOwner {
    numTokensSellForTax = _numTokensSellForTax;
  }

  function _transfer(address from, address to, uint amount) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

    // If buy or sell
    if ((from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify) {
      // On sell and if tax swap enabled
      if (to == uniswapV2Pair && taxSwap) {
        uint contractTokenBalance = balanceOf(address(this));
        // If the contract balance reaches sell threshold
        if (contractTokenBalance >= numTokensSellForTax) {
          uint16 totalTokenTax = buyTax.totalTax + sellTax.totalTax;
          uint16 botTax = buyTax.botTax + sellTax.botTax;
          uint16 teamTax = buyTax.teamTax + sellTax.teamTax;

          uint liquidityTokenCut = (numTokensSellForTax * (buyTax.liquidityTax + sellTax.liquidityTax)) / totalTokenTax;
          uint burnTokenCut;

          // Add tokens to lp
          _swapAndLiquify(liquidityTokenCut);

          // If token burning enabled
          if (buyTax.burnTax != 0 || sellTax.burnTax != 0) {
            burnTokenCut = (numTokensSellForTax * (buyTax.burnTax + sellTax.burnTax)) / totalTokenTax;
            // Send tokens to dead address
            super._transfer(address(this), address(0xdead), burnTokenCut);
          }

          // Swap bot and team tokens for ETH
          _swapTokens(numTokensSellForTax - liquidityTokenCut - burnTokenCut);

          // Distribute to wallets
          (botWallet).call{ value: (address(this).balance * botTax) / (botTax + teamTax) }("");
          (treasuryWallet).call{ value: address(this).balance }("");
        }
      }

      uint transferAmount = amount;
      if (!(excludedFromFee[from] || excludedFromFee[to])) {
        require(launched, "Token not launched");
        uint fees;

        // On sell
        if (to == uniswapV2Pair) {
          fees = sellTax.totalTax;
        // On buy
        } else if (from == uniswapV2Pair) {
          fees = buyTax.totalTax;
        }
        uint tokenFees = (amount * fees) / 100;
        transferAmount -= tokenFees;
        super._transfer(from, address(this), tokenFees);
      }
      super._transfer(from, to, transferAmount);
    } else {
      super._transfer(from, to, amount);
    }
  }

  function _swapTokens(uint tokenAmount) private lockTheSwap {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
  }

  function _swapAndLiquify(uint liquidityTokenCut) private lockTheSwap {
    uint ethHalf = (liquidityTokenCut / 2);
    uint tokenHalf = (liquidityTokenCut - ethHalf);
    uint balanceBefore = address(this).balance;
    _swapTokens(ethHalf);
    uint balanceAfter = (address(this).balance - balanceBefore);
    _addLiquidity(tokenHalf, balanceAfter);
    emit SwapAndLiquify(ethHalf, balanceAfter, tokenHalf);
  }

  function _addLiquidity(uint tokenAmount, uint ethAmount) private lockTheSwap {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(address(this), tokenAmount, 0, 0, liqWallet, block.timestamp);
  }
}