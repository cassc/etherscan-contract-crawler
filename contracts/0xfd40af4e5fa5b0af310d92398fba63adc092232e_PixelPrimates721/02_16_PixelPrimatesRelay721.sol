// contracts/PixelPrimates.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PixelPrimates721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelPrimatesRelay721 is Ownable {
  using SafeMath for uint256;

  PixelPrimates721 private _contractStorage;
  bool private _isInitialized = false;

  uint256 public _primateLimit = 9000;
  uint256 public _primateCount = 0;

  uint256 public itemMintPrice = 5000000000000000; // 0.005 ETH

  // just incase. Balance for this relay contract should always be 0
  function withdraw() external onlyOwner {
    address payable _owner = payable(owner());
    _owner.transfer(address(this).balance);
  }

  function initialize(PixelPrimates721 addr) external onlyOwner {
    require(!_isInitialized, "Contract already initialized");
    _contractStorage = addr;
    _isInitialized = true;
  }

  function updateItemMintPrice(uint256 itemMintPriceWei) public onlyOwner {
    itemMintPrice = itemMintPriceWei;
  }

  function getMintPrice() public view returns (uint256 price) {
    if (_primateCount < 100) {
      return 20000000000000000; // 0.02
    } else if (_primateCount >= 100 && _primateCount < 1000) {
      return 25000000000000000; // 0.025
    } else if (_primateCount >= 1000 && _primateCount < 2000) {
      return 35000000000000000; // 0.035
    } else if (_primateCount >= 2000 && _primateCount < 6000) {
      return 45000000000000000; // 0.045
    } else if (_primateCount >= 6000 && _primateCount < 7000) {
      return 55000000000000000; // 0.055
    } else if (_primateCount >= 7000 && _primateCount < 8000) {
      return 65000000000000000; // 0.065
    } else if (_primateCount >= 8000) {
      return 75000000000000000; // 0.075
    }
  }

  function updateLimits(uint256 value) external onlyOwner {
    _primateLimit = value;
  }

  function checkIfPrimatesMintable(uint256 numberOfTokens) private view {
    require(numberOfTokens <= 10, "Can only mint up to 10 tokens at a time.");
    require(
      _primateCount + numberOfTokens <= _primateLimit,
      "Cannot mint more than the current limit"
    );
    require(
      getMintPrice().mul(numberOfTokens) <= msg.value,
      "Insufficient ether amount was sent"
    );
  }

  function checkIfItemsMintable(uint256 numberOfTokens) private {
    require(
      itemMintPrice.mul(numberOfTokens) <= msg.value,
      "Insufficient ether amount was sent"
    );
  }

  function mintPrimates(uint256 numberOfTokens) external payable {
    require(_isInitialized, "Relay contract has not been initialized!");
    checkIfPrimatesMintable(numberOfTokens);
    address sender = msg.sender;
    _primateCount += numberOfTokens;
    _contractStorage.mintPrimates{ value: msg.value }(
      sender,
      numberOfTokens,
      "random"
    );
  }

  function mintItems(uint256 numberOfTokens) external payable {
    require(_isInitialized, "Relay contract has not been initialized!");
    checkIfItemsMintable(numberOfTokens);
    address sender = msg.sender;
    _contractStorage.mintItems{ value: msg.value }(
      sender,
      numberOfTokens,
      "random"
    );
  }
}