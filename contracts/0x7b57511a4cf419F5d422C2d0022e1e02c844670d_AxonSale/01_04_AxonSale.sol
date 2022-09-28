// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AxonSale is Ownable{
  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////////////////////////
  event newSaleEvent(uint256 e_price, uint256 e_amount, uint256 e_time);
  event newBuyEvent(uint256 e_price, uint256 e_amount, uint256 e_total);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////////////////////////

  uint256 private s_currentPrice;
  uint256 private s_currentAmountToSale;
  uint256 private s_currentEndTime;
  uint256 private s_currentSold;

  uint256 private s_totalsold;

  IERC20 public immutable DAI_CONTRACT;
  IERC20 public s_axonTokenContract;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Constructor
  ////////////////////////////////////////////////////////////////////////////////////////////////// 

  constructor (address p_daiAddress) {
    DAI_CONTRACT = IERC20(p_daiAddress);    
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // Public functions
  //////////////////////////////////////////////////////////////////////////////////////////////////   

  // => View functions

  function getPrice() public view returns(uint256) {
    return s_currentPrice;
  }

  function getAmountPrice(uint256 p_amount) public view returns(uint256) {
    uint256 amountDai = (s_currentPrice / 1000000000000000) * p_amount;
    return amountDai / (1 ether / 1000000000000000);
  }

  function getAmountToSale() public view returns(uint256) {
    return s_currentAmountToSale;
  }

  function getAmountOnSale() public view returns(uint256) {
    return s_currentAmountToSale - s_currentSold;
  }

  function canBuy() public view returns(bool) {
    return (s_currentAmountToSale > s_currentSold) && (block.timestamp <= s_currentEndTime);
  }

  function getAmountSold() public view returns(uint256) {
    return s_currentSold;
  }

  function getTotalAmountSold() public view returns(uint256) {
    return s_totalsold;
  }

  function getTime() public view returns(uint256) {
    return s_currentEndTime;
  }

  function totalCurrentDai() public view returns(uint256) {
    return DAI_CONTRACT.balanceOf(address(this));
  }

  // => Set functions

  function setAxonToken(address p_axonToken) public onlyOwner returns(bool) {
    s_axonTokenContract = IERC20(p_axonToken);

    return true;
  }

  function newSale(uint256 p_price, uint256 p_amount, uint256 p_durationSeconds) public onlyOwner returns(bool) {
    require(block.timestamp > s_currentEndTime, "The previous sale has not yet ended");
    require(p_amount <= s_axonTokenContract.balanceOf(address(this)), "The contract does not have enough balance");
    require(p_price >= 1000000000000000, "Insufficient price");

    s_currentPrice = p_price;
    s_currentAmountToSale = p_amount;
    s_currentEndTime = block.timestamp + p_durationSeconds;
    delete s_currentSold;

    emit newSaleEvent(p_price, p_amount, block.timestamp + p_durationSeconds);

    return true;
  }

  function deleteSale() public onlyOwner returns(bool) {
    
    _deleteSale();
    return true;
  }

  function buyTokens(uint256 p_amount) public returns(bool) {
    require(block.timestamp <= s_currentEndTime, "The sale is over");
    require(s_currentSold + p_amount <= s_currentAmountToSale, "Cant buy more of total sale");

    uint256 amountDai = (s_currentPrice / 1000000000000000) * p_amount;
    amountDai = amountDai / (1 ether / 1000000000000000);

    s_currentSold += p_amount;
    s_totalsold += p_amount;

    require(DAI_CONTRACT.transferFrom(msg.sender, address(this), amountDai), "Failed Dai payment");
    require(s_axonTokenContract.transfer(msg.sender, p_amount), "Failed Axon transfer");

    emit newBuyEvent(s_currentPrice, p_amount, amountDai);

    return true;
  }

  function withdrawDai(address to) public onlyOwner returns(bool) {
    DAI_CONTRACT.transfer(to, DAI_CONTRACT.balanceOf(address(this)));

    return true;
  }

  function withdrawAxon() public onlyOwner returns(bool) {
    _deleteSale();
    s_axonTokenContract.transfer(msg.sender, s_axonTokenContract.balanceOf(address(this)));

    return true;
  }

  function _deleteSale() internal {
    delete s_currentPrice;
    delete s_currentAmountToSale;
    delete s_currentEndTime;
    delete s_currentSold;
  }

}