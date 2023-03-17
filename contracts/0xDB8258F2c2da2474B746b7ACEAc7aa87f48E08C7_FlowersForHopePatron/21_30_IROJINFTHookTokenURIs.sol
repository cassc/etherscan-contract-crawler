// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Interface for an NFT hook to return meta data
/// @author Martin Wawrusch
/// @custom:security-contact [email protected]
interface IROJINFTHookTokenURIs {
  // @notice returns the tokenURI for a contractAddress and tokenId pair. 
  // @dev Requires contract address not null. 
  // @return Either the baseURI + tokenId + ".json" or the tokenURI if set previously.
  function tokenURI(address contractAddress, uint256 tokenId) external view returns (string memory);

}

interface IROJINFTHookTokenURIsSettable {

  /// @notice Updates the token URI for a contract address and token id
  /// @dev While not enforced yet the contract address should be a 721 or 1155 NFT contract
  /// @param contractAddress The address for the contract's base URI
  /// @param tokenId The id of an NFT within the token referenced by contractAddress - The token may not exist yet
  /// @param newTokenURI When set then this URI replaces the auto generated URI derived from baseURI, tokenId and ".json"
  function setTokenURI(address contractAddress, uint256 tokenId, string calldata newTokenURI) external;
}