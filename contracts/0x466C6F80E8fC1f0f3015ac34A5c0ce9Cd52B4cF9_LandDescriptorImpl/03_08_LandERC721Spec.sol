// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../lib/LandLib.sol";

/**
 * @title Land ERC721 Metadata
 *
 * @notice Defines metadata-related capabilities for LandERC721 token.
 *      This interface should be treated as a definition of what metadata is for LandERC721,
 *      and what operations are defined/allowed for it.
 *
 * @author Basil Gorin
 */
interface LandERC721Metadata {
	/**
	 * @notice Presents token metadata in a well readable form,
	 *      with the Internal Land Structure included, as a `PlotView` struct
	 *
	 * @notice Reconstructs the internal land structure of the plot based on the stored
	 *      Tier ID, Plot Size, Generator Version, and Seed
	 *
	 * @param _tokenId token ID to query metadata view for
	 * @return token metadata as a `PlotView` struct
	 */
	function viewMetadata(uint256 _tokenId) external view returns (LandLib.PlotView memory);

	/**
	 * @notice Presents token metadata "as is", without the Internal Land Structure included,
	 *      as a `PlotStore` struct;
	 *
	 * @notice Doesn't reconstruct the internal land structure of the plot, allowing to
	 *      access Generator Version, and Seed fields "as is"
	 *
	 * @param _tokenId token ID to query on-chain metadata for
	 * @return token metadata as a `PlotStore` struct
	 */
	function getMetadata(uint256 _tokenId) external view returns (LandLib.PlotStore memory);

	/**
	 * @notice Verifies if token has its metadata set on-chain; for the tokens
	 *      in existence metadata is immutable, it can be set once, and not updated
	 *
	 * @dev If `exists(_tokenId) && hasMetadata(_tokenId)` is true, `setMetadata`
	 *      for such a `_tokenId` will always throw
	 *
	 * @param _tokenId token ID to check metadata existence for
	 * @return true if token ID specified has metadata associated with it
	 */
	function hasMetadata(uint256 _tokenId) external view returns (bool);

	/**
	 * @dev Sets/updates token metadata on-chain; same metadata struct can be then
	 *      read back using `getMetadata()` function, or it can be converted to
	 *      `PlotView` using `viewMetadata()` function
	 *
	 * @dev The metadata supplied is validated to satisfy (regionId, x, y) uniqueness;
	 *      non-intersection of the sites coordinates within a plot is guaranteed by the
	 *      internal land structure generator algorithm embedded into the `viewMetadata()`
	 *
	 * @dev Metadata for non-existing tokens can be set and updated unlimited
	 *      amount of times without any restrictions (except the constraints above)
	 * @dev Metadata for an existing token can only be set, it cannot be updated
	 *      (`setMetadata` will throw if metadata already exists)
	 *
	 * @param _tokenId token ID to set/updated the metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function setMetadata(uint256 _tokenId, LandLib.PlotStore memory _plot) external;

	/**
	 * @dev Removes token metadata
	 *
	 * @param _tokenId token ID to remove metadata for
	 */
	function removeMetadata(uint256 _tokenId) external;

	/**
	 * @dev Mints the token and assigns the metadata supplied
	 *
	 * @dev Creates new token with the token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Consider minting with `safeMint` (and setting metadata before),
	 *      for the "safe mint" like behavior
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId token ID to mint and set metadata for
	 * @param _plot token metadata to be set for the token ID
	 */
	function mintWithMetadata(address _to, uint256 _tokenId, LandLib.PlotStore memory _plot) external;
}

/**
 * @title Land Descriptor
 *
 * @notice Auxiliary module which is dynamically injected into LandERC721 contract
 *      to override the default ERC721.tokenURI behaviour
 *
 * @notice This can be used, for example, to enable on-chain generation of the SVG
 *      image representation of the land plot, encoding it into base64 string, and
 *      using it instead of token URI pointing to some off-chain sotrage location
 *
 * @dev Can be dynamically injected into LandERC721 at any time, can be dynamically detached
 *      from the LandERC721 once attached (injected)
 *
 * @author Pedro Bergamini, Basil Gorin
 */
interface LandDescriptor {
	/**
	 * @notice Creates SVG image with the land plot metadata painted on it,
	 *      encodes the generated SVG into base64 URI string
	 *
	 * @param _tokenId token ID of the land plot to generate SVG for
	 */
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}