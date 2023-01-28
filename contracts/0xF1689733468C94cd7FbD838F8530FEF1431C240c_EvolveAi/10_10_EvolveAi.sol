// SPDX-License-Identifier: MIT

/**
 * ███████╗██╗   ██╗ ██████╗ ██╗    ██╗   ██╗███████╗     █████╗ ██╗
 * ██╔════╝██║   ██║██╔═══██╗██║    ██║   ██║██╔════╝    ██╔══██╗██║
 * █████╗  ██║   ██║██║   ██║██║    ██║   ██║█████╗      ███████║██║
 * ██╔══╝  ╚██╗ ██╔╝██║   ██║██║    ╚██╗ ██╔╝██╔══╝      ██╔══██║██║
 * ███████╗ ╚████╔╝ ╚██████╔╝███████╗╚████╔╝ ███████╗    ██║  ██║██║
 * ╚══════╝  ╚═══╝   ╚═════╝ ╚══════╝ ╚═══╝  ╚══════╝    ╚═╝  ╚═╝╚═╝
 */

pragma solidity 0.8.17;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EvolveAi is ERC20, Ownable {
  /*|| === STATE VARIABLES === ||*/
  uint public launchDate;
  address payable public marketingWallet;
  address payable public teamWallet;
  address payable public liqWallet;
  address public immutable uniswapV2Pair;
  bool private inSwapAndLiquify;
  bool public launched;
  BuyTax public buyTax;
  SellTax public sellTax;

  uint private _supply = 100000000;
  uint8 private _decimals = 9;
  string private _name = "EvolveAI";
  string private _symbol = "EVOAI";
  uint public numTokensSellForTax = 200000 * 10 ** _decimals;
  bool public taxSwap = true;
  IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  /*|| === STRUCTS === ||*/
  struct BuyTax {
    uint16 liquidityTax;
    uint16 marketingTax;
    uint16 teamTax;
    uint16 burnTax;
    uint16 totalTax;
  }

  struct SellTax {
    uint16 liquidityTax;
    uint16 marketingTax;
    uint16 teamTax;
    uint16 burnTax;
    uint16 totalTax;
  }

  /*|| === MAPPINGS === ||*/
  mapping(address => bool) public excludedFromFee;

  /*|| === EVENTS === ||*/
  event SwapAndLiquify(uint tokensSwapped, uint ethReceived, uint tokensIntoLiqudity);

  /*|| === CONSTRUCTOR === ||*/
  constructor(address payable _marketingWallet, address payable _teamWallet, address payable _liqWallet) ERC20(_name, _symbol) {
    _mint(msg.sender, (_supply * 10 ** _decimals)); /// Mint and send all tokens to deployer
    marketingWallet = _marketingWallet;
    teamWallet = _teamWallet;
    liqWallet = _liqWallet;
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH()); /// Create uniswap pair
    excludedFromFee[address(uniswapV2Router)] = true;
    excludedFromFee[msg.sender] = true;
    excludedFromFee[marketingWallet] = true;
    excludedFromFee[teamWallet] = true;
    excludedFromFee[liqWallet] = true;

    buyTax = BuyTax(1, 2, 1, 0, 4);
    sellTax = SellTax(1, 2, 1, 0, 4);
  }

  /*|| === MODIFIERS === ||*/
  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  /*|| === RECIEVE FUNCTION === ||*/
  receive() external payable {}

  /*|| === EXTERNAL FUNCTIONS === ||*/

  /**
   * @notice Enables initial trading and logs time of activation. Once trading is started it cannot be stopped.
   */
  function launch() external onlyOwner {
    launched = true;
    launchDate = block.timestamp;
  }

  function setMarketingWallet(address payable _marketingWallet) external onlyOwner {
    require(_marketingWallet != address(0), "Address cannot be 0 address");
    marketingWallet = _marketingWallet;
  }

  function setTeamWallet(address payable _teamWallet) external onlyOwner {
    require(_teamWallet != address(0), "Address cannot be 0 address");
    teamWallet = _teamWallet;
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

  function setBuyTax(uint16 liquidityTax, uint16 marketingTax, uint16 teamTax, uint16 burnTax) external onlyOwner {
    uint16 totalTax = liquidityTax + marketingTax + teamTax + burnTax;
    require(totalTax <= 10, "ERC20: total tax must not be greater than 10");
    buyTax = BuyTax(liquidityTax, marketingTax, teamTax, burnTax, totalTax);
  }

  function setSellTax(uint16 liquidityTax, uint16 marketingTax, uint16 teamTax, uint16 burnTax) external onlyOwner {
    uint16 totalTax = liquidityTax + marketingTax + teamTax + burnTax;
    require(totalTax <= 10, "ERC20: total tax must not be greater than 10");
    sellTax = SellTax(liquidityTax, marketingTax, teamTax, burnTax, totalTax);
  }

  function setTokensToSellForTax(uint _numTokensSellForTax) external onlyOwner {
    numTokensSellForTax = _numTokensSellForTax;
  }

  /*|| === INTERNAL FUNCTIONS === ||*/
  function _transfer(address from, address to, uint amount) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

    /// If buy or sell
    if ((from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify && launched) {
      /// On sell and if tax swap enabled
      if (to == uniswapV2Pair && taxSwap) {
        uint contractTokenBalance = balanceOf(address(this));
        /// If the contract balance reaches sell threshold
        if (contractTokenBalance >= numTokensSellForTax) {
          uint16 totalTokenTax = buyTax.totalTax + sellTax.totalTax;
          uint16 marketingTax = buyTax.marketingTax + sellTax.marketingTax;
          uint16 teamTax = buyTax.teamTax + sellTax.teamTax;

          uint liquidityTokenCut = (numTokensSellForTax * (buyTax.liquidityTax + sellTax.liquidityTax)) / totalTokenTax;
          uint burnTokenCut;

          /// Add tokens to lp
          _swapAndLiquify(liquidityTokenCut);

          /// If burns are enabled
          if (buyTax.burnTax != 0 || sellTax.burnTax != 0) {
            burnTokenCut = (numTokensSellForTax * (buyTax.burnTax + sellTax.burnTax)) / totalTokenTax;
            /// Send tokens to dead address
            super._transfer(address(this), address(0xdead), burnTokenCut);
          }

          /// Swap marketing and team tokens for ETH
          _swapTokens(numTokensSellForTax - liquidityTokenCut - burnTokenCut);

          /// Distribute to corresponding wallets
          (marketingWallet).call{ value: (address(this).balance * marketingTax) / (marketingTax + teamTax) }("");
          (teamWallet).call{ value: address(this).balance }("");
        }
      }

      uint transferAmount = amount;
      if (!(excludedFromFee[from] || excludedFromFee[to])) {
        uint fees;

        /// On sell
        if (to == uniswapV2Pair) {
          fees = sellTax.totalTax;

          /// On buy
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

  /*|| === PRIVATE FUNCTIONS === ||*/

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