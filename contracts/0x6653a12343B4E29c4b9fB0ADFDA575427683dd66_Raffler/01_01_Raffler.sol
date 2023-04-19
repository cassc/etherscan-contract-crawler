// SPDX-License-Identifier: MIT
// @author Mouradif <mouradif.eth>

// This contract was written for determining the winner of an Othedeed for
// Otherside NFT in a raffle organized by Mutariuum Universe
// (mutariuum-universe.eth).
// But this can actually be used by anyone for any raffle so I tried to make it
// more general purpose.
//
// Builders Enjoy!

pragma solidity 0.8.19;

contract Raffler {
  error MaxMustBeHigherThanMin();
  error EmptyListProvided();
  error Unauthorized();
  error Inactive();

  event RandomWallet(address indexed wallet);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event Paused(address account);
  event Unpaused(address account);

  address public owner;
  bool public active;

  constructor() {
    owner = msg.sender;
  }

  function randomWallet(address[] calldata wallets) external {
    if (!active) {
      revert Inactive();
    }
    if (wallets.length == 0) {
      revert EmptyListProvided();
    }
    uint256 index;
    unchecked {
      index = uint256(
        keccak256(
          abi.encodePacked(
            msg.sender,
            block.prevrandao
          )
        )
      ) % wallets.length;
    }
    emit RandomWallet(wallets[index]);
  }

  function toggle() external {
    if (msg.sender != owner) {
      revert Unauthorized();
    }
    active = !active;
    if (active) {
      emit Unpaused(msg.sender);
    } else {
      emit Paused(msg.sender);
    }
  }

  function transferOwnership(address newOwner) external {
    if (msg.sender != owner) {
      revert Unauthorized();
    }
    owner = newOwner;
    emit OwnershipTransferred(msg.sender, newOwner);
  }
}