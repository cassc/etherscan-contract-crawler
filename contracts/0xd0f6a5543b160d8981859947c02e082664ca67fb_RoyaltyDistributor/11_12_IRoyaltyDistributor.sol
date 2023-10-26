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

interface IRoyaltyDistributor {
  /// @dev Emitted when funds are distributed to producers
  /// @param receiver The address that received the distributed funds
  /// @param amount The amount of funds received
  /// @param releaseId The id of the release for which the distribution occurred
  event FundsDistributed(address receiver, uint256 amount, uint128 releaseId);

  /// @dev Emitted when ether funds are received
  /// @param sender The sender of the funds
  /// @param amount The amount of funds received
  event EthReceived(address sender, uint256 amount);

  /// @dev Thrown if an ETH transfer fails
  /// @param destination The receiver of the ether
  /// @param amount The amount of ether being sent
  error EthTransferFailed(address destination, uint256 amount);

  /// @dev Thrown if an invalid amount is provided
  error InvalidAmount();

  /// @dev Thrown if attempting to transfer a zero eth amount
  error InvalidEthAmount();

  /// @notice Distribute funds accumulated from secondary marketplaces to producers and the GRT royalty wallet
  /// @dev Only callable by the DROP_MANAGER_ROLE
  /// @param amount The total value of the sale to be distributed
  /// @param receiver The address of the receiver of the funds percentage (i.e the producer)
  /// @param percentage The percentage of funds to distribute. Should account for decimal precision of 10**2
  /// @param royaltyWallet The address if the royalty wallet to receive remaining funds not sent to the producer
  function distributeFunds(
    uint256 amount,
    address receiver,
    uint16 percentage,
    address royaltyWallet,
    uint128 releaseId
  ) external;
}