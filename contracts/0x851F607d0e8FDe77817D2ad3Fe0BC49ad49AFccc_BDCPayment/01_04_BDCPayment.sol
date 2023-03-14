// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

struct SizeState {
  uint256 price;
  uint256 amount;
}

contract BDCPayment is Ownable, ReentrancyGuard {

  event ChipsPurchased(address receiver, string size, uint256 price, uint256 amount);

  address t1 = 0xaE04ea9B67FC32f38D2e614e519f60a967316E3B;

  mapping (string => SizeState) public sizeStates;

  constructor() {
    sizeStates["xs"] = SizeState(0.0099 ether, 15);
    sizeStates["sm"] = SizeState(0.0199 ether, 30);
    sizeStates["md"] = SizeState(0.027 ether, 50);
    sizeStates["lg"] = SizeState(0.078 ether, 150);
    sizeStates["xl"] = SizeState(0.149 ether, 300);
  }

  function purchaseChips(string memory _size) public payable {
    SizeState memory _sizeState = sizeStates[_size];

    require(msg.value >= _sizeState.price, "Ether value sent is not correct");

    emit ChipsPurchased(msg.sender, _size, _sizeState.price, _sizeState.amount);
  }

  function setSizeState(string memory _size, uint256 _price, uint256 _amount) public onlyOwner {
    sizeStates[_size] = SizeState(_price, _amount);
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 _balance = address(this).balance;

    require(payable(t1).send(_balance));
  }

}