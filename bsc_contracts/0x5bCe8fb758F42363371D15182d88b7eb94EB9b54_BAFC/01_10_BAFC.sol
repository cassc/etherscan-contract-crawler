// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BEP20Detailed.sol";
import "./BEP20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract BAFC is BEP20Detailed, BEP20 {
  using SafeMath for uint256; 
  mapping(address => bool) public liquidityPool;
  mapping(address => bool) public whitelistTax;

  uint8 public buyTax;
  uint8 public sellTax;
  uint256 private taxAmount;
  address public marketingWallet;
  uint8 public treasuryPercent;

  IUniswapV2Router02 public uniswapV2Router;
  uint256 public swapTokensAtAmount;
  uint256 public swapTokensMaxAmount;
  bool public swapping;
  bool public enableTax;

  event changeTax(bool _enableTax, uint8 _sellTax, uint8 _buyTax);
  event changePairForTax(address lpAddress, bool taxenable);
  event changeMarketingWallet(address marketingWallet);
  event changeWhitelistTax(address _address, bool status); 
  
 
  constructor() payable BEP20Detailed("Bored Ape Football Club Token", "BAFC", 18) public {
    uint256 totalSupply = 100000000 * 10**uint256(decimals());
    _mint(msg.sender, totalSupply);
    sellTax = 5;
    buyTax = 3;
    enableTax = false;
    marketingWallet = 0x98640a136c53f0c52EE25224c5821ad37Af6eEA5;

    whitelistTax[address(this)] = true;
    whitelistTax[marketingWallet] = true;
    whitelistTax[owner()] = true;
    whitelistTax[address(0)] = true;
  
    uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    _approve(address(this), address(uniswapV2Router), ~uint256(0));
    swapTokensAtAmount = totalSupply*2/10**6; 
    swapTokensMaxAmount = totalSupply*2/10**4; 
  }

  

  //update fee
  function enablePairForTax(address _lpAddress, bool _taxenable) external onlyOwner {
    liquidityPool[_lpAddress] = _taxenable;
    emit changePairForTax(_lpAddress, _taxenable);
  }
  function setMarketingWallet(address _marketingWallet) external onlyOwner {
    marketingWallet = _marketingWallet;
    whitelistTax[marketingWallet] = true;
    emit changeMarketingWallet(_marketingWallet);
  } 

  function setTaxes(bool _enableTax, uint8 _sellTax, uint8 _buyTax) external onlyOwner {
    require(_sellTax + _buyTax < 20,"Need: Tax < 20");
    enableTax = _enableTax;
    sellTax = _sellTax;
    buyTax = _buyTax;
    emit changeTax(_enableTax,_sellTax,_buyTax);
  }

  function setWhitelist(address _address, bool _status) external onlyOwner {
    whitelistTax[_address] = _status;
    emit changeWhitelistTax(_address, _status);
  }
  function getTaxes() external view returns (uint8 _sellTax, uint8 _buyTax) {
    return (sellTax, buyTax);
  } 

  function setSwapTokensAtAmount(uint256 _swapTokensAtAmount, uint256 _swapTokensMaxAmount) external onlyOwner {
    swapTokensAtAmount = _swapTokensAtAmount;
    swapTokensMaxAmount = _swapTokensMaxAmount;
  }

  //Tranfer and tax
  function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
    if (amount == 0) {
        super._transfer(sender, receiver, 0);
        return;
    }

    if(enableTax && !whitelistTax[sender] && !whitelistTax[receiver]){
      //swap
      uint256 contractTokenBalance = balanceOf(address(this));
      bool canSwap = contractTokenBalance >= swapTokensAtAmount;
      if ( canSwap && !swapping && sender != owner() && receiver != owner() ) {
          if(contractTokenBalance > swapTokensMaxAmount){
            contractTokenBalance = swapTokensMaxAmount;
          }
          swapping = true;
          swapAndSendToFee(contractTokenBalance);
          swapping = false;
      }

      if(liquidityPool[sender] == true) {
        //It's an LP Pair and it's a buy
        taxAmount = (amount * buyTax) / 100;
      } else if(liquidityPool[receiver] == true) {
        //It's an LP Pair and it's a sell
        taxAmount = (amount * sellTax) / 100;
      } else {
        taxAmount = 0;
      }
      
      if(taxAmount > 0) {
          super._transfer(sender, address(this) , taxAmount);
      }    
      super._transfer(sender, receiver, amount - taxAmount);
    }else{
      super._transfer(sender, receiver, amount);
    }
  }

  function swapAndSendToFee(uint256 tokens) private {
    swapTokensForEth(tokens);
    uint256 newBalance = address(this).balance;
    if(newBalance>0){
      payable(marketingWallet).transfer(newBalance);
    }
  }

  function swapTokensForEth(uint256 tokenAmount) private {
      // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();
      // make the swap
      try
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        )
      {} catch {}
  }
    function withdrawAll() external onlyOwner {
        require(_msgSender().send(address(this).balance));
    }
  receive() external payable {}
}