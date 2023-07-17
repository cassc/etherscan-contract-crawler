// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "../../interfaces/internal/INFTLazyMintedCollectionMintCountTo.sol";

import "../roles/MinterRole.sol";
import "./SequentialMintCollection.sol";

error LazyMintedCollection_Mint_Count_Must_Be_Greater_Than_Zero();

/**
 * @title Common functions for collections in which all tokens are defined at the time of collection creation.
 * @dev This implements the INFTLazyMintedCollectionMintCountTo ERC-165 interface.
 * @author HardlyDifficult
 */
abstract contract LazyMintedCollection is INFTLazyMintedCollectionMintCountTo, MinterRole, SequentialMintCollection {
  function _initializeLazyMintedCollection(address payable _creator, address _approvedMinter) internal {
    // Initialize access control
    AdminRole._initializeAdminRole(_creator);
    if (_approvedMinter != address(0)) {
      MinterRole._initializeMinterRole(_approvedMinter);
    }
  }

  /**
   * @notice Mint `count` number of NFTs for the `to` address.
   * @dev This is only callable by an address with either the MINTER_ROLE or the DEFAULT_ADMIN_ROLE.
   * @param count The number of NFTs to mint.
   * @param to The address to mint the NFTs for.
   * @return firstTokenId The tokenId for the first NFT minted.
   * The other minted tokens are assigned sequentially, so `firstTokenId` - `firstTokenId + count - 1` were minted.
   */
  function mintCountTo(uint16 count, address to) public virtual hasPermissionToMint returns (uint256 firstTokenId) {
    if (count == 0) {
      revert LazyMintedCollection_Mint_Count_Must_Be_Greater_Than_Zero();
    }

    unchecked {
      // If +1 overflows then +count would also overflow, since count > 0.
      firstTokenId = latestTokenId + 1;
    }
    // If the mint will exceed uint32, the addition here will overflow. But it's not realistic to mint that many tokens.
    latestTokenId = latestTokenId + count;
    uint256 lastTokenId = latestTokenId;

    for (uint256 i = firstTokenId; i <= lastTokenId; ) {
      _safeMint(to, i);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Allows a collection admin to destroy this contract only if
   * no NFTs have been minted yet or the minted NFTs have been burned.
   * @dev Once destructed, a new collection could be deployed to this address (although that's discouraged).
   */
  function selfDestruct() external onlyAdmin {
    _selfDestruct();
  }

  /**
   * @inheritdoc ERC721Upgradeable
   * @dev The function here asserts `onlyAdmin` while the super confirms ownership.
   */
  function _burn(uint256 tokenId) internal virtual override onlyAdmin {
    super._burn(tokenId);
  }

  /**
   * @inheritdoc IERC165Upgradeable
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable) returns (bool isSupported) {
    isSupported =
      interfaceId == type(INFTLazyMintedCollectionMintCountTo).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}