// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../Chainlink/VRFConsumerBase.sol";
import "../ChefAvatar.sol";

/// @title A title that should describe the contract/interface
/// https://docs.chain.link/docs/vrf-contracts/
/// You can get the keyhash and vrfCoordinator from here https://docs.chain.link/docs/vrf-contracts/
contract ChefRevealProvider is VRFConsumerBase, Ownable {
  using SafeERC20 for IERC20;

  uint256 public fee;
  uint256 public randomNumber;
  bytes32 public immutable keyHash;
  bytes32 public requestId;

  event FeeChanged(uint256 newFee);

  ChefAvatar public immutable chefAvatar;

  /// @dev Ctor
  /// @param VRFCoordinator: address of the VRF coordinator
  /// @param LINKToken: address of the LINK token
  constructor(
    address VRFCoordinator,
    address LINKToken,
    bytes32 _keyHash,
    uint256 _fee,
    ChefAvatar _chefAvatar
  )
    VRFConsumerBase(
			VRFCoordinator, // VRF Coordinator
			LINKToken  // LINK Token
		)
  {
    keyHash = _keyHash;
    fee = _fee;
    chefAvatar = _chefAvatar;
  }

  /// @notice Change the fee
  /// @param _fee: new fee (in LINK)
  function setFee(uint256 _fee) external onlyOwner {
    fee = _fee;

    emit FeeChanged(_fee);
  }

  /// @notice It allows the admin to withdraw tokens sent to the contract
  /// @dev Only callable by owner.
  /// @param token: the address of the token to withdraw
  /// @param amount: the number of token amount to withdraw
  function withdrawTokens(address token, uint256 amount) external onlyOwner {
    IERC20(token).safeTransfer(_msgSender(), amount);
  }

  /// @notice Request randomness from a user-provided seed
  /// @dev Only callable by RevealConsumer.
  /// @param userProvidedSeed: extra entrpy for the VRF
  function getRandomNumber(uint256 userProvidedSeed) external {
    require(msg.sender == address(chefAvatar), "only ChefAvatar");
    require(LINK.balanceOf(address(this)) >= fee, "insufficient LINK tokens");
    require(requestId == bytes32(0), "request already made");

    requestId = requestRandomness(keyHash, fee, userProvidedSeed);
  }

  /// @notice Callback function used by ChainLink's VRF Coordinator
  function fulfillRandomness(bytes32 incomingRequestId, uint256 randomness) internal override {
    require(incomingRequestId == requestId, "Wrong requestId");

    chefAvatar.reveal(randomness);
  }
}