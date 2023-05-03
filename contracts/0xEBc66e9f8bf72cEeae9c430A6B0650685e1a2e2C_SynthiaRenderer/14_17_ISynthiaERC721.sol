pragma solidity >=0.6.2 <0.9.0;

interface ISynthiaERC721 {
  /// @dev This function returns the total number of customizable traits
  function getTotalTraits() external view returns (uint256);

  /// @dev You can get the name of a trait by it's index. Indices are zero based
  /// and the max length can be retrieved by the getTotalTraits function. The lower the trait index
  /// the lower the trait layer when the image is rendered. Trait 0 will be on the bottom, trait 1 will be placed
  /// on top of trait 0 and so on.
  function getTraitNameByIndex(
    uint256 index
  ) external view returns (string memory);

  /// @dev Convenience method to determine if a specified trait is custom
  function hasCustomTrait(uint tokenId, uint idx) external view returns (bool);

  /// @dev Returns that contract address which contains the token ID for a given trait set for a given token ID.
  /// If no custom trait has been set then this function MUST return the zero address
  function getTraitContractAddress(
    uint tokenId,
    uint index
  ) external view returns (address);

  /// @dev Returns the token ID which represents the custom trait set on a given soul bound token.
  /// If no custom trait is set this function MUST throw. You can
  /// Check if a custom trait is set by verifying that the getTraitPointer return value is not the 0 address
  /// Token ownership MUST be checked here. The owner of the NFT and trait NFT MUST be the same.
  function getTraitTokenId(
    uint tokenId,
    uint index
  ) external view returns (uint);

  /// @dev Function MUST be called by owner of NFT. If a non-owner tries to call this function it MUST throw.
  /// Clears any associated external trait for the given token ID and index.
  function clearTrait(uint tokenId, uint index) external;

  /// @dev Function MUST be called by owner of NFT. If a non-owner tries to call this function it MUST throw.
  /// traitTokenId MUST be owned by owner of tokenId, if not function MUST throw. As a safeguard, index argument MUST match
  /// what is returned by getTraitIndex function from the pointer contract.
  function setTrait(
    uint tokenId,
    address traitContractAddress,
    uint traitTokenId,
    uint index
  ) external;

  /// @dev This function MUST return the base 64 URL of the fully layered image.
  function getImage(uint tokenId) external view returns (string memory);
}