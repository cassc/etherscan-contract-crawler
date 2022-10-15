// SPDX-License-Identifier: MIT
/*
twitter  : https://twitter.com/HalloweeninuEN
TeleGram : https://t.me/halloweeninuport
*/
pragma solidity ^0.8.4.0;
import "./BEP20Detailed.sol";
import "./BEP20.sol";
import "./SafeMathInt.sol";
contract HALO is BEP20Detailed, BEP20 {
  using SafeMath for uint256;
  using SafeMathInt for int256;

  mapping(address => bool) public whitelistTax;

  uint8 public Tax;

  uint256 private taxAmount;

  address public marketingPool;
  address public LiquidityPool2;
  address public DevPool;

  bool public tradingOpen;

  uint8 public mktTaxPercent;
  uint8 public DevTaxPercent;

  //swap 

  bool public enableTax;
  uint256 public launchedAt;
  event changeTax(bool _enableTax, uint8 _Tax);
  event changeTaxPercent(uint8 _mktTaxPercent,uint8 _LiquidityTaxPercent,uint8 _DevTaxPercent,uint8 _RewardsPoolTaxPercent);
  event changeWhitelistTax(address _address, bool status);  
  
  event changeMarketingPool(address marketingPool);
  event changeDevPool(address DevPool);


  constructor() payable BEP20Detailed("Halloween Inu", "HALO", 18) {
    uint256 totalTokens = 100000000 * 10**uint256(decimals());
    _mint(msg.sender, totalTokens);
    Tax = 9;
    enableTax = true;
    tradingOpen = false;
    marketingPool   =      0x460211eF60a07dcDEBe0fACd06f75Ba1A986Ea60;
    DevPool         =      0xc79B3EDC16e01AAa29CAEE6797C01c5fb4ac9408;

    
    mktTaxPercent = 30;
    DevTaxPercent = 30;

    
    whitelistTax[address(this)] = true;
    whitelistTax[DevPool] = true;
    whitelistTax[marketingPool] = true;
    whitelistTax[owner()] = true;
    whitelistTax[address(0)] = true;
    
  }

  function setMarketingPool(address _marketingPool) external onlyOwner {
    marketingPool = _marketingPool;
    whitelistTax[marketingPool] = true;
    emit changeMarketingPool(_marketingPool);
  }  

  function setDevPool(address _DevPool) external onlyOwner {
    DevPool = _DevPool;
    whitelistTax[DevPool] = true;
    emit changeDevPool(_DevPool);
  }  
  function setliq(address _LiquidityPool2) external onlyOwner {
    LiquidityPool2 = _LiquidityPool2;
    whitelistTax[_LiquidityPool2] = true;

  }  


  function setTaxes(bool _enableTax, uint8 _Tax) external onlyOwner {
    require(_Tax < 10);

    enableTax = _enableTax;
    Tax = _Tax;

    emit changeTax(_enableTax,_Tax);
  }


  function setWhitelist(address _address, bool _status) external onlyOwner {
    whitelistTax[_address] = _status;
    emit changeWhitelistTax(_address, _status);
  }

 

  //Tranfer and tax
  function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
    taxAmount = 0;
    if (amount == 0) {
        super._transfer(sender, receiver, 0);
        return;
    }
    if(enableTax && !whitelistTax[sender] && !whitelistTax[receiver]){
      require(tradingOpen, "Trading not open yet");
      if(block.number - launchedAt <= 3 ){
        //is bot
        taxAmount = (amount * 80) / 100;
      }else{
        taxAmount = (amount * Tax) / 100;
      }

      
      if(taxAmount > 0) {
        uint256 mktTax = taxAmount.div(100).mul(mktTaxPercent);
        uint256 DevTax = taxAmount.div(100).mul(DevTaxPercent);
        uint256 Pool2Tax = taxAmount - mktTax -  DevTax;
        if(mktTax>0){
          super._takefee(sender, marketingPool, mktTax);
        }
        if(DevTax>0){
          super._takefee(sender, DevPool, DevTax);
        }
        if(Pool2Tax>0){
          super._takefee(sender, LiquidityPool2 , Pool2Tax);
        }
      }    
      super._transfer(sender, receiver, amount - taxAmount);
    }else{
      super._transfer(sender, receiver, amount);
    }
  }
  function launch() external onlyOwner {
    require(tradingOpen == false, "Already open ");
    launchedAt = block.number;
    tradingOpen = true;

    }

  //common
  function burn(uint256 amount) external {
    amount = amount * 10**uint256(decimals());
    _burn(msg.sender, amount);
  }


  receive() external payable {}
}