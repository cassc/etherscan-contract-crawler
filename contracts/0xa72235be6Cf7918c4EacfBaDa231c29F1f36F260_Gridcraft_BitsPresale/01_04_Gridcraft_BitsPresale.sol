// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Gridcraft_BitsPresale is Ownable {

  address public saleTokenContract = 0xcbc6922BB75e55d7cA5DAbcF0EA2D7787Fd023f6;

  address public withdrawWallet = 0x5d28e347583e70b5F7B0631CA5ab5575bD37Cbcd;

  uint public multiplier = 862069;

  uint public minBuy = 0.0166 ether;
  uint public maxBuy = 66.671 ether;

  bool public saleActive;

  constructor(){
  }

  function sale() external payable {
    require(saleActive, "Sale not active");
    require(msg.value > minBuy, "Below min buy");
    require(msg.value < maxBuy, "Above max buy");

    uint256 balance = presaleTokenSupply();
    uint256 toReceive = bitsReceived(msg.value);
    require(toReceive <= balance, "Asked amount exceeds supply");

    IERC20(saleTokenContract).transfer(msg.sender, toReceive);
  }

  function bitsReceived(uint256 ethValue) public view returns(uint256) {
    return ethValue * multiplier;
  }

  function presaleTokenSupply() public view returns(uint256) {
    uint256 balance = IERC20(saleTokenContract).balanceOf(address(this));

    return balance;
  }

  function setTokenAddress(address _newAddress) external onlyOwner {
    saleTokenContract = _newAddress;
  }

  function setWithdrawWallet(address _newAddress) external onlyOwner {
    withdrawWallet = _newAddress;
  }

  function setSaleRate(uint256 _newRate) external onlyOwner {
    multiplier = _newRate;
  }

  function setMinAndMaxBuys(uint256 _minBuy, uint256 _maxBuy) external onlyOwner {
    minBuy = _minBuy;
    maxBuy = _maxBuy;
  }

  function withdrawSaleToken() external {
    withdrawToken(saleTokenContract);
  }

  function toggleSale() external {
    require(msg.sender == withdrawWallet || msg.sender == owner(), "Not allowed");

    saleActive = !saleActive;
  }

  function withdrawToken(address tokenAddress) public {
    require(msg.sender == withdrawWallet || msg.sender == owner(), "Not allowed");

    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    IERC20(tokenAddress).transfer(withdrawWallet, balance);
  }

  function withdrawEth() external {
    require(msg.sender == withdrawWallet || msg.sender == owner(), "Not allowed");

    uint balance = address(this).balance;
    payable(withdrawWallet).transfer(balance);
  }

}