// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IRoyaltyDistributor.sol";
import "../libraries/GrtLibrary.sol";

/// @title Royalty Distributor
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor mfbevan (mfbevan.eth)
/// @notice Disitribute secondary marketplace royalties
/// @dev This contract accumulates royalties from secondary marketplaces such as OpenSea
///      Admins of the Drop Manager contract can call `distributeSecondaryRoyalties` which will in turn distribute the
///      funds that are sitting in this contract
contract RoyaltyDistributor is IRoyaltyDistributor, AccessControl {
  using SafeMath for uint256;

  bytes32 public constant DROP_MANAGER_ROLE = keccak256("DROP_MANAGER_ROLE");
  uint256 public constant PERCENTAGE_PRECISION = 10**2;

  constructor(address superUser) {
    GrtLibrary.checkZeroAddress(superUser, "super user");
    _grantRole(DEFAULT_ADMIN_ROLE, superUser);
  }

  function distributeFunds(
    uint256 amount,
    address receiver,
    uint16 percentage,
    address royaltyWallet,
    uint128 releaseId
  ) external onlyRole(DROP_MANAGER_ROLE) {
    if (amount == 0) {
      revert InvalidAmount();
    }

    uint256 receiverAmount = amount.mul(percentage).div(
      PERCENTAGE_PRECISION * 100
    );
    uint256 royaltyAmount = amount.sub(receiverAmount);

    emit FundsDistributed(receiver, receiverAmount, releaseId);
    emit FundsDistributed(royaltyWallet, royaltyAmount, releaseId);

    _callSendEth(receiver, receiverAmount);
    _callSendEth(royaltyWallet, royaltyAmount);
  }

  /// @dev Wrapper for sending eth to an address including error handling
  /// @param destination The address to send the amount to
  /// @param amount The amount to send
  function _callSendEth(address destination, uint256 amount) internal {
    GrtLibrary.checkZeroAddress(destination, "destination");
    if (amount == 0) {
      revert InvalidEthAmount();
    }
    (bool success, ) = destination.call{value: amount}("");
    if (!success) {
      revert EthTransferFailed(destination, amount);
    }
  }

  /// @notice Called when ETH is received from OpenSea secondary marketplace sales
  /// @dev This function is required to be able to receive ether into the contract
  receive() external payable {
    emit EthReceived(msg.sender, msg.value);
  }
}