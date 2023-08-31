//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @title ReflectedNFT - immitation of original collection contract
/// @author 0xslava
/// @notice Must have same name and symbol as original collection
/// @dev Deployed on first bridge of collection to current chain
/// @dev Tokens can be minted and burned by Mirror contract (owner)
/// @dev Inherits ERC721URIStorage to be able to handle collections with any tokenURI function logic
/// @dev ERC721URIStorage allows to point to exact same metadata as in original collection
contract ReflectedNFT is ERC721URIStorage, Ownable {
	constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

	/// @notice Mints NFT with given tokenId and tokenURI
	/// @notice tokenId and tokenURI are exact same as of original NFT
	/// @notice Can only be called by Mirror contract (owner)
	/// @param to Address to transer token to
	/// @param tokenId ID of original token
	/// @param _tokenURI URI of original token
	function mint(address to, uint tokenId, string calldata _tokenURI) public onlyOwner {
		_mint(to, tokenId);
		_setTokenURI(tokenId, _tokenURI);
	}

	/// @notice Destroys NFT reflection (copy) on bridge
	/// @notice can only be called by Mirror contract (owner)
	/// @param from Address to burn token from
	/// @param tokenId ID of token
	/// @dev have owner requirement to prevent vulnerability with burning token from any address in bridge process
	/// @dev because there is no such requirement in Mirror contract
	function burn(address from, uint256 tokenId) public onlyOwner {
		require(from == ownerOf(tokenId), 'ReflectedNFT: caller is not the owner');
		_burn(tokenId);
	}
}