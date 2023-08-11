// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "./SequentialMintCollection.sol";

error TokenLimitedCollection_Max_Token_Id_May_Not_Be_Cleared(uint256 currentMaxTokenId);
error TokenLimitedCollection_Max_Token_Id_May_Not_Increase(uint256 currentMaxTokenId);
error TokenLimitedCollection_Max_Token_Id_Must_Be_Greater_Than_Current_Minted_Count(uint256 currentMintedCount);
error TokenLimitedCollection_Max_Token_Id_Must_Not_Be_Zero();

/**
 * @title Defines an upper limit on the number of tokens which may be minted by this collection.
 * @author HardlyDifficult
 */
abstract contract TokenLimitedCollection is SequentialMintCollection {
  /**
   * @notice The max tokenId which can be minted.
   * @dev This max may be less than the final `totalSupply` if 1 or more tokens were burned.
   * @return The max tokenId which can be minted.
   */
  uint32 public maxTokenId;

  /**
   * @notice Emitted when the max tokenId supported by this collection is updated.
   * @param maxTokenId The new max tokenId. All NFTs in this collection will have a tokenId less than
   * or equal to this value.
   */
  event MaxTokenIdUpdated(uint256 indexed maxTokenId);

  function _initializeTokenLimitedCollection(uint32 _maxTokenId) internal {
    if (_maxTokenId == 0) {
      // When 0 is desired, the collection may choose to simply not call this initializer.
      revert TokenLimitedCollection_Max_Token_Id_Must_Not_Be_Zero();
    }

    maxTokenId = _maxTokenId;
  }

  /**
   * @notice Allows the owner to set a max tokenID.
   * This provides a guarantee to collectors about the limit of this collection contract, if applicable.
   * @dev Once this value has been set, it may be decreased but can never be increased.
   * @param _maxTokenId The max tokenId to set, all NFTs must have a tokenId less than or equal to this value.
   */
  function _updateMaxTokenId(uint32 _maxTokenId) internal {
    if (_maxTokenId == 0) {
      revert TokenLimitedCollection_Max_Token_Id_May_Not_Be_Cleared(maxTokenId);
    }
    if (maxTokenId != 0 && _maxTokenId >= maxTokenId) {
      revert TokenLimitedCollection_Max_Token_Id_May_Not_Increase(maxTokenId);
    }
    if (latestTokenId > _maxTokenId) {
      revert TokenLimitedCollection_Max_Token_Id_Must_Be_Greater_Than_Current_Minted_Count(latestTokenId);
    }

    maxTokenId = _maxTokenId;
    emit MaxTokenIdUpdated(_maxTokenId);
  }
}