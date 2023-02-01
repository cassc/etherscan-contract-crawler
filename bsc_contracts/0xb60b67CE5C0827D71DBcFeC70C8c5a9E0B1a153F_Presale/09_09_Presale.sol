//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BNBUSD.sol";
import "./IAccessControl.sol";

//Liquidity Would Be done Manually for security Reasons 

contract Presale is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;
  
  BNBTicker ticker = new BNBTicker();

  mapping (address => uint256) private _contributions;
  mapping (address => uint256) private userTokens;
  mapping (address => bool) private isAdmin;

  IERC20 private _token;
  address payable private _wallet;
  // Per $
  uint256 private _rate = 10;
  uint256 private _weiRaised;
  uint256 public _endICO =1680168660000;
  uint256 public _minPurchase = 0.1 * 10**18;
  uint256 public _maxPurchase = 1000 * 10**18;
  // In $
  uint256 private hardCap = 1_000_000;
  // In $
  uint256 private softCap = 150_000;

  uint256 public availableTokensICO = 10_000_000 * 10**18;
  bool public startRefund = false;


  function minPurchase() public view returns (uint256) {
        return _minPurchase;
  }
  function maxPurchase() public view returns (uint256) {
        return _maxPurchase;
  }
   function endICO() public view returns (uint256) {
        return _endICO;
  }
  function token() public view returns (address) {
        return address(_token);
  }

  function getRate() public view returns (uint256) {
        return ticker.getLatestPriceEth().mul(_rate);
  }

function getHardCap() public view returns (uint256) {
    return hardCap.div(ticker.getLatestPriceEth());
}

function getSoftCap() public view returns (uint256) {    
    return softCap.div(ticker.getLatestPriceEth());
}


  modifier onlyAdmin() {
    require(isAdmin[_msgSender()], "ICO: only Admin can call this functionality");
    _;
  }

  event TokensPurchased(address  purchaser, address  beneficiary, uint256 value, uint256 amount);
  event Refund(address recipient, uint256 amount);
  constructor (address payable wallet, IERC20 token) {
    require(wallet != address(0), "Pre-Sale: wallet is the zero address");
    require(address(token) != address(0), "Pre-Sale: token is the zero address");
    _wallet = wallet;
    _token = token;
    isAdmin[owner()] = true;
  }


  receive () external payable {
    if(_endICO > 0 && block.timestamp < _endICO){
      buyTokens(_msgSender());
    }
    else{
      revert('Pre-Sale is closed');
    }
  }
  
  
  //Start Pre-Sale
  function startICO(uint256 endDate) external onlyAdmin icoNotActive() {
    require(endDate > block.timestamp, 'duration should be > 0');
    _endICO = endDate; 
    _weiRaised = 0;
  }
  
  function stopICO() external onlyAdmin icoActive(){
    _endICO = 0;
  }
  
  function activateRefund() external onlyAdmin icoActive(){
    startRefund = true;
  }
  
  //Pre-Sale 
  function buyTokens(address beneficiary) public nonReentrant icoActive payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);
    uint256 tokens = _getTokenAmount(weiAmount);
    userTokens[beneficiary] =  userTokens[beneficiary].add(tokens);
    _weiRaised = _weiRaised.add(weiAmount);
    availableTokensICO = availableTokensICO - tokens;
    _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
    
    emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
  }

  function claimTokens() external nonReentrant {
    uint256 tokens = userTokens[_msgSender()];
    _processPurchase(_msgSender(), tokens);
    userTokens[_msgSender()] = 0;
  }

  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
    require(weiAmount >= _minPurchase, 'have to send at least: minPurchase');
    require(weiAmount <= _maxPurchase, 'have to send max: maxPurchase');
    require((_weiRaised+weiAmount) < getHardCap().mul(10**18), 'Hard Cap reached');
    if (weiAmount == 0) {
      revert('Crowdsale: weiAmount is 0');
    } else {
      this;
    }
  }

  function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
    _token.transfer(beneficiary, tokenAmount);
  }


  function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
    _deliverTokens(beneficiary, tokenAmount);
  }


  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(getRate());
  }

  function forwards() external onlyAdmin {
    require(startRefund == false);
    require(address(this).balance > 0, 'Contract has no money');
    _wallet.transfer(address(this).balance);
  }
  
  function checkContribution(address addr) public view returns(uint256){
    return _contributions[addr];
  }
  function checkTokens(address addr) public view returns(uint256){
    return userTokens[addr];
  }
  
  function setRate(uint256 newRate) external onlyAdmin icoNotActive {
    require(newRate > 0, "Pre-Sale: rate is 0");
    _rate = newRate;
  }
  
  function setAvailableTokens(uint256 amount) public onlyAdmin icoNotActive{
    availableTokensICO = amount;
  }

  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }
  
  function setWalletReceiver(address payable newWallet) external onlyAdmin {
    _wallet = newWallet;
  }
  
  function setHardCap(uint256 value) external onlyAdmin {
    hardCap = value;
  }
  
  function setSoftCap(uint256 value) external onlyAdmin {
    softCap = value;
  }
  
  function setMaxPurchase(uint256 value) external onlyAdmin {
    _maxPurchase = value;
  }
  
  function setMinPurchase(uint256 value) external onlyAdmin {
    _minPurchase = value;
  }
  
  function takeTokens(IERC20 tokenAddress)  public onlyAdmin icoNotActive {
    IERC20 tokenBEP = tokenAddress;
    uint256 tokenAmt = tokenBEP.balanceOf(address(this));
    require(tokenAmt > 0, 'BEP-20 balance is 0');
    tokenBEP.transfer(_wallet, tokenAmt);
  }
  
  function refundMe() public icoNotActive {
    require(startRefund == true, 'no refund available');
    uint amount = _contributions[msg.sender];
    if (address(this).balance >= amount) {
      _contributions[msg.sender] = 0;
      if (amount > 0) {
        address payable recipient = payable(msg.sender);
        recipient.transfer(amount);
        emit Refund(msg.sender, amount);
      }
    }
  }

  function setAdmin(address _admin) external onlyOwner {
    require(_admin != address(0), "address is zero");
    isAdmin[_admin] = true;
  }
  
  modifier icoActive() {
    require(_endICO > 0 && block.timestamp < _endICO && availableTokensICO > 0, "ICO must be active");
    _;
  }
  
  modifier icoNotActive() {
    require(_endICO < block.timestamp, 'ICO should not be active');
    _;
  }
    
}