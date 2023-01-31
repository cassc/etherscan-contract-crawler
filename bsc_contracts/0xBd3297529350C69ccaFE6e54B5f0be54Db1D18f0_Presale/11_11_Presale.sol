//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BNBUSD.sol";
import "./IUniswapV2Router02.sol";
import "./IAccessControl.sol";

contract Presale is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;
  
  BNBTicker ticker = new BNBTicker();

  mapping (address => uint256) private _contributions;
  mapping (address => uint256) private userTokens;
  mapping (address => bool) private isAdmin;

  IERC20 public _token;
  uint256 private _tokenDecimals = 18;
  address payable private _wallet;
  // Per $
  uint256 public _rate = 10;
  uint256 public _weiRaised;
  uint256 public endICO =1680168660000;
  uint256 public minPurchase = 0.1 * 10**18;
  uint256 public maxPurchase = 1000 * 10**18;
  // In $
  uint256 public hardCap = 1_000_000;
  // In $
  uint256 public softCap = 150_000;

  uint256 public availableTokensICO = 10_000_000 * 10**18;

  function getRate() public view returns (uint256) {
        return ticker.getLatestPriceEth().mul(_rate);
  }

function getHardCap() public view returns (uint256) {
    return hardCap.div(ticker.getLatestPriceEth());
}

function getSoftCap() public view returns (uint256) {    
    return softCap.div(ticker.getLatestPriceEth());
}

  bool public startRefund = false;

  IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

  modifier onlyAdmin() {
    require(isAdmin[_msgSender()], "Presale: only Admin can call this functionality");
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
    if(endICO > 0 && block.timestamp < endICO){
      buyTokens(_msgSender());
    }
    else{
      revert('Pre-Sale is closed');
    }
  }
  
  
  //Start Pre-Sale
  function startICO(uint256 endDate) external onlyAdmin icoNotActive() {
    require(endDate > block.timestamp, 'duration should be > 0');
    endICO = endDate; 
    _weiRaised = 0;
  }
  
  function stopICO() external onlyAdmin icoActive(){
    endICO = 0;
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

  function claimTokens() external nonReentrant icoNotActive {
    uint256 tokens = userTokens[_msgSender()];
    _processPurchase(_msgSender(), tokens);
    userTokens[_msgSender()] = 0;
  }

  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
    require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
    require(weiAmount <= maxPurchase, 'have to send max: maxPurchase');
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

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public {
    // approve token transfer to cover all possible scenarios
    _token.approve(address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(_token),
        tokenAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        _wallet,
        block.timestamp
    );
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
    maxPurchase = value;
  }
  
  function setMinPurchase(uint256 value) external onlyAdmin {
    minPurchase = value;
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
    require(endICO > 0 && block.timestamp < endICO && availableTokensICO > 0, "ICO must be active");
    _;
  }
  
  modifier icoNotActive() {
    require(endICO < block.timestamp, 'ICO should not be active');
    _;
  }
    
}