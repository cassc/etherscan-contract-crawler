// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../../libraries/TimeLibrary.sol";
import "../shared/Constants.sol";

import "../../interfaces/internal/INFTLazyMintedCollectionMintCountTo.sol";

import "./LazyMintedCollection.sol";

error TimeLimitedCollection_Mint_End_Time_Must_Be_In_The_Future();
error TimeLimitedCollection_Mint_End_Time_Too_Far_In_The_Future();
/// @param mintEndTime The time in seconds after which no more editions can be minted.
error TimeLimitedCollection_Minting_Has_Ended(uint256 mintEndTime);

/**
 * @title Defines an upper limit on the number of tokens which may be minted by this collection.
 * @author HardlyDifficult
 */
abstract contract TimeLimitedCollection is LazyMintedCollection {
  using SafeCast for uint256;
  using TimeLibrary for uint32;
  using TimeLibrary for uint256;

  /**
   * @notice The time in seconds after which no more editions can be minted.
   */
  uint32 public mintEndTime;

  function _initializeTimeLimitedCollection(uint256 _mintEndTime) internal {
    if (_mintEndTime.hasBeenReached()) {
      revert TimeLimitedCollection_Mint_End_Time_Must_Be_In_The_Future();
    }

    if (_mintEndTime > block.timestamp + MAX_SCHEDULED_TIME_IN_THE_FUTURE) {
      // Prevent arbitrarily large values from accidentally being set.
      revert TimeLimitedCollection_Mint_End_Time_Too_Far_In_The_Future();
    }

    // The check above ensures this cast is safe until 2104.
    mintEndTime = uint32(_mintEndTime);
  }

  /**
   * @inheritdoc LazyMintedCollection
   */
  function mintCountTo(uint16 count, address to) public virtual override returns (uint256 firstTokenId) {
    if (mintEndTime.hasExpired()) {
      revert TimeLimitedCollection_Minting_Has_Ended(mintEndTime);
    }
    firstTokenId = super.mintCountTo(count, to);
  }

  /**
   * @notice Get the number of NFTs that can still be minted.
   * @return count Number of NFTs that can still be minted.
   * @dev An edition can have up to (2^32-1) tokens, but this function will return max uint256 until the mintEndTime has
   * passed. Returning max uint256 indicates to consumers that there are effectively unlimited tokens available to mint.
   * It's not realistic for the mints to overflow the actual uint32 number of tokens available.
   */
  function numberOfTokensAvailableToMint() external view returns (uint256 count) {
    if (!mintEndTime.hasExpired()) {
      count = type(uint256).max;
    } else {
      count = 0;
    }
  }
}