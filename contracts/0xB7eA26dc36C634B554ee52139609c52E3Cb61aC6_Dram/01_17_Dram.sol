// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RealTimePrice.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Dram is ERC20, Pausable, Ownable, ERC20Burnable, ReentrancyGuard  {

  uint _totalSupply = 1000000000 * 10 ** decimals();
  uint public minInvest = 10 * 10 ** decimals();
  uint public maxInvest = 10000 * 10 ** decimals();
  constructor() ERC20("Dram", "DRAM") {
    setReleasedPercentFor(msg.sender, 100);
    _mint(msg.sender, _totalSupply);
    approve(msg.sender, _totalSupply);
  }

  uint public priceUSD;
  uint public releasedPercent;

  RealTimePrice realTimePrice = RealTimePrice(address(0xf3336EfD5C7969FDb9A82B4218D832C41F76412f));
  IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));

  using Counters for Counters.Counter;
  using SafeERC20 for ERC20;

  mapping(address => uint) addressToReleased;
  mapping(address => uint) addressToWhitdrawed;

  event ReleasedEdited(uint _percent);
  event PriceEdited(uint _price);
  event Buy(address _address, uint _totalAmount, uint _bonusAmount, uint _ethPrice, uint _price, uint _paymentAmount, string _currency, uint _timestamp);
  event Airdrop(address _address, uint _amount, uint _timestamp);
  event Withdraw(uint _amount);

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override
  {
    address owner = super.owner();
    if(msg.sender != owner) {
      uint withdrawable = getWithdrawableAmountFor(from);
      require(amount <= withdrawable, "This amount is not transferable now");
      addressToWhitdrawed[from] = amount;
    }
    super._beforeTokenTransfer(from, to, amount);
  }

  function setReleasedPercent(uint _percent) public onlyOwner {
    releasedPercent = _percent;
    emit ReleasedEdited(releasedPercent);
  }

  function setMaxInvest(uint amount) public onlyOwner {
    maxInvest = amount;
  }

  function setMinInvest(uint amount) public onlyOwner {
    minInvest = amount;
  }

  function getEthPrice() public view returns(int256) {
    return realTimePrice.getThePrice();
  }

  function setPriceUSD(uint _price) public onlyOwner {
    priceUSD = _price;
    emit PriceEdited(_price);
  }

  function setReleasedPercentFor(address _address, uint _percent) public onlyOwner{
    addressToReleased[_address] = _percent;
  }

  function airdrop(address _address, uint amount) public onlyOwner {
    address _owner = super.owner();
    _transfer(_owner, _address, amount);
    addInvestor(_address);
    emit Airdrop(_address, amount, block.timestamp);
  }

  function getReleasedPercentFor(address _address) public view returns(uint) {
    uint _percent;
    if(addressToReleased[_address] != 0) {
        _percent = addressToReleased[_address];
    } else {
        _percent = releasedPercent;
    }
    return _percent;
  }

  function getWhitdrawedAmountFor(address _address) public view returns(uint) {
    return addressToWhitdrawed[_address];
  }

  function getWithdrawableAmountFor(address _address) public view returns(uint) {
    uint balance = balanceOf(_address);
    uint amount;
    uint _percent = getReleasedPercentFor(_address);
    uint withdrawed = getWhitdrawedAmountFor(_address);
    uint totalInvest = withdrawed + balance;
    amount = (totalInvest * _percent / 100) - withdrawed;
    require(amount >= 0, "Something is wrong with your account");
    return amount;
  }

  Counters.Counter private _stageIdCounter;
  Counters.Counter private _holderCounter;

  uint _priceConversionDecimals = 8;
  function buy() payable external {
    require(msg.value > 0, "Need to send exact amount of wei");
    uint currentPrice = uint(realTimePrice.getThePrice());
    uint usdtValue = currentPrice * msg.value / (10 ** _priceConversionDecimals);
    require(usdtValue >= minInvest && usdtValue <= maxInvest, "Invesment amount not acceptable");
    uint tokenAmount = usdtValue / (priceUSD) * (10 ** 18);
    uint bonusAmount = getBuyBonusPercent(usdtValue) * tokenAmount / 100;
    uint finalAmount = tokenAmount + bonusAmount;
    address _owner = super.owner();
    _transfer(_owner, msg.sender, finalAmount);
    addInvestor(msg.sender);
    emit Buy(msg.sender, finalAmount, bonusAmount, currentPrice, priceUSD, msg.value, "Native", block.timestamp);
  }

  function buyUSDT(uint amount) public payable {
    require(amount >= minInvest && amount <= maxInvest, "Invesment amount not acceptable");
    address _owner = super.owner();
    uint currentPrice = uint(realTimePrice.getThePrice());
    uint tokenAmount = uint(amount) / priceUSD * (10 ** 18);
    uint bonusAmount = getBuyBonusPercent(amount) * tokenAmount / 100;
    uint finalAmount = tokenAmount + bonusAmount;
    usdt.transferFrom(msg.sender, _owner, amount);
    _transfer(_owner, msg.sender, finalAmount);
    addInvestor(msg.sender);
    emit Buy(msg.sender, finalAmount, bonusAmount, currentPrice, priceUSD, amount, "USDT", block.timestamp);
  }

  mapping(address => uint) _investors;
  mapping(uint => address) _reverse;
  Counters.Counter private _investorCount;
  function getInvestorsCount() public view onlyOwner returns(uint) {
    return _investorCount.current();
  }

  function addInvestor(address _address) private {
    if(_investors[_address] == 0) {
      _investorCount.increment();
      uint current = _investorCount.current();
      _investors[_address] = current;
      _reverse[current] = _address;
    }
  }

  function getInvestors(uint from, uint to) public view onlyOwner returns(address[] memory) {
    address[] memory list = new address[](to - from);
    uint counter = 0;
    for(uint i = from + 1; i <= to; i++) {
      list[counter] = _reverse[i];
      counter += 1;
    }
    return list;
  }

  function withdraw(uint _amount) public onlyOwner {
    require(_amount > 0, "Amount must be more than zero");
    require(_amount <address(this).balance , "Requested amount is more than balance");
    payable(msg.sender).transfer(_amount);
    emit Withdraw(_amount);
  }

  function income() public view onlyOwner returns(uint) {
    return address(this).balance;
  }

  Counters.Counter private _bonusIdCounter;
  struct Bonus {
    uint from;
    uint to;
    uint bonusPercent;
  }

  mapping(uint => Bonus) _bonuses;
  function createBonus(uint _from, uint _to, uint _percent) public onlyOwner {
    _bonusIdCounter.increment();
    uint currentId = _bonusIdCounter.current();
    Bonus memory bonus = Bonus (
      _from,
      _to,
      _percent
    );
    _bonuses[currentId] = bonus;
  }

  function deleteBonuses() public onlyOwner {
    for(uint i = 1; i <= _bonusIdCounter.current(); i++) {
      delete _bonuses[i];
    }
    _bonusIdCounter.reset();
  }

  function getBonuses() public view returns(Bonus[] memory) {
    Bonus[] memory bonuses = new Bonus[](_bonusIdCounter.current());
    for(uint i = 0; i < _bonusIdCounter.current(); i++) {
      bonuses[i] = _bonuses[i + 1];
    }
    return bonuses;
  }

  function getBuyBonusPercent(uint _usdValue) public view returns(uint) {
    uint count = _bonusIdCounter.current();
    uint percent;
    for(uint i = 1; i <= count; i++) {
      if(_usdValue >= _bonuses[i].from && _usdValue < _bonuses[i].to) {
        percent = _bonuses[i].bonusPercent;
      }
    }
    return percent;
  }

  function getCurrentTime()
  public
  virtual
  view
  returns(uint256){
    return block.timestamp;
  }
}