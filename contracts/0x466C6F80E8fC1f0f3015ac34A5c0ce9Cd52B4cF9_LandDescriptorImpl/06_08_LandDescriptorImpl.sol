// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/LandERC721Spec.sol";
import "../lib/LandSvgLib.sol";

/**
 * @title Land Descriptor Implementation
 *
 * @notice Basic implementation of the LandDescriptor interface
 *
 * @author Pedro Bergamini, Basil Gorin
 */
contract LandDescriptorImpl is LandDescriptor {
	/**
	 * @inheritdoc LandDescriptor
	 */
	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		// assuming the function was called by the LandERC721 contract itself,
		// fetch the token metadata from it
		LandLib.PlotView memory _plot = LandERC721Metadata(msg.sender).viewMetadata(_tokenId);

		// unpack the `_plot` structure and delegate generation into the lib
		return LandSvgLib.constructTokenURI(
			_plot.regionId,
			_plot.x,
			_plot.y,
			_plot.tierId,
			_plot.size,
			_plot.landmarkTypeId,
			_plot.sites
		);
	}
}