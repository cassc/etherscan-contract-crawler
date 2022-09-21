//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoyaltyDistributor is AccessControl {

  event RoyaltiesDistributed(address royaltyReceivers, uint256 royaltyAmount);
  event ReceiverUpdated(address previousReceiver, address newReceiver);

  address[] public royaltyReceivers;

  constructor(
    address[] memory _royaltyReceivers 
  ) {
    royaltyReceivers = _royaltyReceivers;
    for( uint256 i=0; i < royaltyReceivers.length; i++) {
      _grantRole(keccak256(abi.encodePacked(i)), royaltyReceivers[i]);
      _setRoleAdmin(keccak256(abi.encodePacked(i)), keccak256(abi.encodePacked(i)));
    }
  }
  
  function balanceOfContract() public view returns(uint256) { 
    return address(this).balance;
  }
  
  function receiveRoyalties() external payable {}

  /**
  *@dev Using this function a role name is returned if the inquired 
  *     address is present in the royaltyReceivers array
  *@param inquired is the address used to find the role name
  */
  function getRoleName(address inquired) external view returns (bytes32) {
    for(uint256 i=0; i < royaltyReceivers.length; i++) {
      if(royaltyReceivers[i] == inquired) {
        return keccak256(abi.encodePacked(i));
      }
    }
    revert("Incorrect address");
  }

  /**
  *@dev This function returns the royalty amount that is calculated by 
  *     dividing the contract balance by the number of addresses in royaltyReceivers
  */
  function _calculateRoyaltyAmount() internal view returns (uint256 royaltyAmount) {
    royaltyAmount = (balanceOfContract() / royaltyReceivers.length);
  }

  /**
  *@dev This function distributes the royalties this contract received 
  *     equally to all addresses in royaltyReceivers
  */
  function royaltyTransfer() external {
    uint256 royaltyAmount = _calculateRoyaltyAmount();
    for( uint256 i=0; i < royaltyReceivers.length; i++) {
      payable(royaltyReceivers[i]).transfer(royaltyAmount);
      emit RoyaltiesDistributed(royaltyReceivers[i], royaltyAmount); 
    }
  }

  /**
  *@dev This function updates the royalty receiving address
  *@param previousReceiver is the address that was given a role before
  *@param newReceiver is the new address that replaces the previous address
  */
  function updateRoyaltyReceiver(address previousReceiver, address newReceiver) external {
    for(uint256 i=0; i < royaltyReceivers.length; i++) {
      if(royaltyReceivers[i] == previousReceiver) {
        require(hasRole(keccak256(abi.encodePacked(i)), msg.sender));
        royaltyReceivers[i] = newReceiver;
        emit ReceiverUpdated(previousReceiver, newReceiver);
        return;
      }
    }
    revert("Incorrect address for previousReceiver");
  }  
}