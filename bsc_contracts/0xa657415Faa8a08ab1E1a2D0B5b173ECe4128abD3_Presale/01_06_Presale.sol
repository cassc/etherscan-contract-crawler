// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Presale is Ownable {
  using SafeERC20 for IERC20;

  // Presale
  uint public price = 100;
  uint public minUSDTAmount = 10 ether;
  // Referral percentages
  uint public constant REFERRAL_PERCENT = 10;
  // Tokens for referral bonus
  uint public referralTokens = 0;

  IERC20 private USDT;
  IERC20 private Token;

  constructor(address usdt_, address token_) {
    require(usdt_ != address(0x0));
    require(token_ != address(0x0));
    USDT = IERC20(usdt_);
    Token = IERC20(token_);
    Token.approve(address(this), type(uint256).max);
  }

  /**
   * @dev Set price, can only be increased from previous value
   */
  function setPrice(uint _price) public onlyOwner {
    require(_price > price, 'Price can only be increased');
    price = _price;
  }

  /**
   * @dev Set referralTokens amount
   */
  function setReferralTokens(uint _referralTokens) public onlyOwner {
    referralTokens = _referralTokens;
  }

  /**
   * @dev Widthdraw tokens by owner
   */
  function transferToken(address token_, address to_, uint amount) external onlyOwner{
    IERC20 tokenContract = IERC20(token_);
    tokenContract.approve(address(this), type(uint256).max);
    tokenContract.safeTransferFrom(address(this), to_, amount);
  }

  /**
   * @dev Returns balance minus referral tokens
   */
  function pureBalance() public view returns (uint) {
    return Token.balanceOf(address(this)) - referralTokens;
  }

  /**
   * @dev Converts USDT amount to Token amount based on price
   */
  function _getAmount(uint _usdtAmount) private view returns (uint) {
    return _usdtAmount * price;
  }

  /**
   * @dev Transfers Token to Buyer in exchange of USDT
   */
  function _buy(uint _usdtAmount) private {
    // Transfer USDT to contract
    USDT.safeTransferFrom(msg.sender, owner(), _usdtAmount);
    // Transfer Token to buyer
    Token.safeTransferFrom(address(this), msg.sender, _getAmount(_usdtAmount));

    emit Buy(msg.sender, _usdtAmount, price, _getAmount(_usdtAmount));
  }

  /**
   * @dev Transfers Token to Buyer in exchange of USDT
   */
  function _referral(uint _usdtAmount, address referral_) private {
    uint referralAmount = _getAmount(_usdtAmount) / 100 * REFERRAL_PERCENT;

    // Transfer referral bonus Token to buyer
    Token.safeTransferFrom(address(this), msg.sender, referralAmount);
    referralTokens -= referralAmount;
    emit Referral(msg.sender, _usdtAmount, referralAmount);

    // Transfer referral bonus Token to referrer
    Token.safeTransferFrom(address(this), referral_, referralAmount);
    referralTokens -= referralAmount;
    emit Referral(referral_, _usdtAmount, referralAmount);
  }

  /**
   * @dev Buy token with USDT
   */
  function buy(uint _usdtAmount) public {
    require(_usdtAmount >= minUSDTAmount, "Minimum USDT amount is 10");
    _buy(_usdtAmount);
  }

  /**
   * @dev Buy token with USDT through referral
   */
  function buy(uint _usdtAmount, address referral_) public {
    require(_usdtAmount >= minUSDTAmount, "Minimum USDT amount is 10");
    _buy(_usdtAmount);

    if (referral_ != address(0x0) && referral_ != msg.sender) {
      _referral(_usdtAmount, referral_);
    }
  }

  event Buy(address indexed buyer, uint usdt, uint price, uint token);
  event Referral(address indexed beneficiary, uint token, uint bonus);
}