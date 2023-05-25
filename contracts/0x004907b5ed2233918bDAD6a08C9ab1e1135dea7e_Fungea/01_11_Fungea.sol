//SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9;

/** 
    The mushrooms are here to rule the world.
    
    https://t.me/fungea
    https://twitter.com/FungeaERC
    https://fungea.world/
    https://docs.fungea.world/

    #play2burn
 **/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Fungea is ERC20, Ownable {
  using SafeMath for uint256;

  IUniswapV2Router02 public immutable uniswapV2Router;

  address public uniswapV2Pair;
  address public devWallet =
    address(0x0ABdFDd65932410743B10262389AC4D4E451C91B);

  mapping(address => bool) public isExcludedFromFee;
  mapping(address => bool) public isExcludedMaxTransactionAmount;

  uint256 public buyTax = 4;
  uint256 public sellTax = 4;
  uint256 public transferTax = 20; // Transfer Tax between Wallets. Only active until all characters have been created

  uint256 public maxWallet = 40000000 * 1e18; // 4% from total supply maxWallet
  uint256 public maxTransactionAmount = 40000000 * 1e18;

  bool private swapping;
  bool public tradingActive = false;

  event BuyTaxUpdated(uint256 buyTax);
  event TransferTaxUpdated(uint256 transferTax);
  event SellTaxUpdated(uint256 sellTax);
  event DevWalletUpdated(address newWallet);
  event BurnedToken(uint256 amount);

  constructor() ERC20("Fungea", "FUNGEA") {
    uint256 _totalSupply = 1000000000 * 1e18;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    isExcludedFromFee[address(this)] = true;
    isExcludedFromFee[address(uniswapV2Router)] = true;
    isExcludedFromFee[msg.sender] = true;
    isExcludedFromFee[devWallet] = true;

    isExcludedMaxTransactionAmount[owner()] = true;
    isExcludedMaxTransactionAmount[address(this)] = true;
    isExcludedMaxTransactionAmount[address(0xdead)] = true;

    _mint(msg.sender, _totalSupply);
  }

  // Daily burn of taxed token. Burn amount depending on in-game burn of $SPORES
  function burn(uint256 _burnAmount) external onlyOwner {
    super._transfer(address(this), address(0xdead), _burnAmount);
    emit BurnedToken(_burnAmount);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      devWallet,
      block.timestamp
    );
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(
      balanceOf(from) >= amount,
      "ERC20: transfer amount exceeds balance"
    );

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    uint256 transferAmount;
    uint256 contractTokenBalance;
    uint256 taxShare;

    if (from == uniswapV2Pair || to == uniswapV2Pair) {
      if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
        transferAmount = amount;
      } else {
        require(tradingActive, "Trading is not active.");
        // SELL
        if (from != uniswapV2Pair) {
          if (!isExcludedMaxTransactionAmount[from]) {
            require(
              amount <= maxTransactionAmount,
              "Exceeds maxTransactionAmount"
            );
          }

          taxShare = amount.mul(sellTax).div(100);
          super._transfer(from, address(this), taxShare);

          transferAmount = amount.sub(taxShare);
          contractTokenBalance = balanceOf(address(this));

          if (
            contractTokenBalance > 0 &&
            !swapping &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to] &&
            taxShare > 0
          ) {
            swapping = true;

            swapTokensForEth(taxShare);

            swapping = false;
          }
        }
        // BUY, tax to contract for future burn
        else {
          if (!isExcludedMaxTransactionAmount[to]) {
            require(
              amount <= maxTransactionAmount,
              "Exceeds maxTransactionAmount"
            );
            require(amount + balanceOf(to) <= maxWallet, "Exceeds maxWallet");
          }

          taxShare = amount.mul(buyTax).div(100);
          transferAmount = amount.sub(taxShare);
          super._transfer(from, address(this), taxShare);
        }
      }

      super._transfer(from, to, transferAmount);
    } else {
      // Transfer between wallets, only taxed until all Chars have been created
      if (
        !isExcludedFromFee[from] && !isExcludedFromFee[to] && transferTax > 0
      ) {
        taxShare = amount.mul(transferTax).div(100);
        transferAmount = amount.sub(taxShare);
        super._transfer(from, address(this), taxShare);
        super._transfer(from, to, transferAmount);
      } else {
        super._transfer(from, to, amount);
      }
    }
  }

  function updateBuyTax(uint256 _buyTax) external onlyOwner {
    buyTax = _buyTax;
    require(buyTax <= 20, "Must keep fees at 20% or less");
    emit BuyTaxUpdated(buyTax);
  }

  function updateTransferTax(uint256 _transferTax) external onlyOwner {
    transferTax = _transferTax;
    require(transferTax <= 50, "Must keep fees at 50% or less");
    emit TransferTaxUpdated(buyTax);
  }

  function updateSellTax(uint256 _sellTax) external onlyOwner {
    sellTax = _sellTax;
    require(sellTax <= 20, "Must keep fees at 20% or less");
    emit SellTaxUpdated(buyTax);
  }

  function updateDevWallet(address _newWallet) external onlyOwner {
    devWallet = _newWallet;
    emit DevWalletUpdated(_newWallet);
  }

  function excludeFromFee(address _address) external onlyOwner {
    isExcludedFromFee[_address] = true;
  }

  function includeToFee(address _address) external onlyOwner {
    isExcludedFromFee[_address] = false;
  }

  function enableTrading() external onlyOwner {
    tradingActive = true;
  }

  function withdrawAll(address payable _to) external onlyOwner {
    _to.transfer(address(this).balance);
  }

  receive() external payable {}
}