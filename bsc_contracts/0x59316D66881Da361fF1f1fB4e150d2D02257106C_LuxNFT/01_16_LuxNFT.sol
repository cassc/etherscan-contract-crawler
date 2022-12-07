// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract LuxNFT is ERC721, ERC721Enumerable, Pausable, Ownable {
	using Counters for Counters.Counter;

	Counters.Counter private _tokenIdCounter;
	string public baseURI;

	constructor() ERC721('LuxNFT', 'LuxGloDAO') {}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function safeMint(address to) public onlyOwner {
		uint256 tokenId = _tokenIdCounter.current();
		_tokenIdCounter.increment();
		_safeMint(to, tokenId);
	}

	function burn(uint256 _id) public onlyOwner {
		_burn(_id);
	}

	function setBaseURI(string memory _uri) public onlyOwner {
		baseURI = _uri;
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId,
		uint256 batchSize
	) internal override(ERC721, ERC721Enumerable) whenNotPaused {
		super._beforeTokenTransfer(from, to, tokenId, batchSize);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	// The following functions are overrides required by Solidity.

	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}