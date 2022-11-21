// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TipJar
/// @author conceptcodes.eth
/// @notice This contract allows users to send tips to the the owner
/// @dev This contract is used to collect crypto tips
/// @dev This contract allows the owner to withdraw the tips
contract TipJar is Ownable {
  // mapping to store tips and tipper
  mapping(address => uint256) public tips;

  // event to log tips collected
  event TipReceived(address indexed from, uint256 amount);

  // event to log tips withdrawn
  event TipsWithdrawn(address indexed to, uint256 amount);

  /// @notice constructor to initialize the total tips collected to 0
  constructor() payable { }

  /// @notice modifer to check if the tip amount is greater than 0
  /// @param _amount the tip amount to check
  modifier checkTipAmount(uint256 _amount) {
    require(_amount > 0, "TipJar: Tip amount must be greater than 0");
    _;
  }

  /// @notice fallback payable function to receive tips
  /// @dev this function is called when a user sends ether to this contract
  /// @dev we usee the checkTipAmount modifier to check if the tip amount is greater than 0
  receive() 
  external 
  payable 
  checkTipAmount(msg.value) {
    // update mapping of tips
    tips[msg.sender] += msg.value;

    // emit event to log tips collected
    emit TipReceived(msg.sender, msg.value);
  }

  /// @notice funtion to send tips to this contract
  function sendTip() 
  public 
  payable 
  checkTipAmount(msg.value) {
    (bool success, ) = payable(address(this)).call{value : msg.value}("");
    require(success == true, "TipJar: Transfer Failed"); 
  }

  /// @notice function to withdraw tips collected
  /// @dev uses the onlyOwner modifier from the Ownable contract
  function withdrawTips() 
  public 
  onlyOwner {
    // calculate the amount to withdraw
    uint256 amount = address(this).balance;

    require(address(this).balance > 0, "TipJar: Insufficient Balance");

    // transfer the amount to the owner
    payable(owner()).transfer(amount);

    // emit event to log tips withdrawn
    emit TipsWithdrawn(owner(), amount);
  }

  /// @notice function to show the contract balance
  /// @dev uses the onlyOwner modifier from the Ownable contract
  function getContractBalance() 
  public 
  view 
  onlyOwner 
  returns (uint256) {
    return address(this).balance;
  }

}