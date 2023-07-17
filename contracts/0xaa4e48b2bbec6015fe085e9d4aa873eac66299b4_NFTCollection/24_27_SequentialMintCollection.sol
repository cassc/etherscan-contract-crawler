// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

import "../../interfaces/standards/royalties/ITokenCreator.sol";

error SequentialMintCollection_Caller_Is_Not_Owner(address owner);
error SequentialMintCollection_Minted_NFTs_Must_Be_Burned_First(uint256 totalSupply);

/**
 * @title Extends the OZ ERC721 implementation for collections which mint sequential token IDs.
 * @author batu-inal & HardlyDifficult
 */
abstract contract SequentialMintCollection is ITokenCreator, ERC721BurnableUpgradeable {
  /****** Slot 0 (after inheritance) ******/
  /**
   * @notice The creator/owner of this NFT collection.
   * @dev This is the default royalty recipient if a different `paymentAddress` was not provided.
   * @return The collection's creator/owner address.
   */
  address payable public owner;

  /**
   * @notice The tokenId of the most recently created NFT.
   * @dev Minting starts at tokenId 1. Each mint will use this value + 1.
   * @return The most recently minted tokenId, or 0 if no NFTs have been minted yet.
   */
  uint32 public latestTokenId;

  /**
   * @notice Tracks how many tokens have been burned.
   * @dev This number is used to calculate the total supply efficiently.
   */
  uint32 private burnCounter;

  // 32-bits free space

  /****** End of storage ******/

  /**
   * @notice Emitted when this collection is self destructed by the creator/owner/admin.
   * @param admin The account which requested this contract be self destructed.
   */
  event SelfDestruct(address indexed admin);

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert SequentialMintCollection_Caller_Is_Not_Owner(owner);
    }
    _;
  }

  function _initializeSequentialMintCollection(address payable _creator) internal {
    owner = _creator;
  }

  /**
   * @notice Allows the collection owner to destroy this contract only if
   * no NFTs have been minted yet or the minted NFTs have been burned.
   */
  function _selfDestruct() internal {
    if (totalSupply() != 0) {
      revert SequentialMintCollection_Minted_NFTs_Must_Be_Burned_First(totalSupply());
    }

    emit SelfDestruct(msg.sender);
    selfdestruct(payable(msg.sender));
  }

  function _burn(uint256 tokenId) internal virtual override {
    unchecked {
      // Number of burned tokens cannot exceed latestTokenId which is the same size.
      ++burnCounter;
    }
    super._burn(tokenId);
  }

  /**
   * @inheritdoc ITokenCreator
   * @dev The tokenId param is ignored since all NFTs return the same value.
   */
  function tokenCreator(uint256 /* tokenId */) external view returns (address payable creator) {
    creator = owner;
  }

  /**
   * @notice Returns the total amount of tokens stored by the contract.
   * @dev From the ERC-721 enumerable standard.
   * @return supply The total number of NFTs tracked by this contract.
   */
  function totalSupply() public view returns (uint256 supply) {
    unchecked {
      // Number of tokens minted is always >= burned tokens.
      supply = latestTokenId - burnCounter;
    }
  }
}