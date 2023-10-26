// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '../utils/AccessProtected.sol';

contract ApexaNFT is ERC721('Apex Athletes', 'AA'), AccessProtected {
	using Counters for Counters.Counter;
	using Strings for uint256;

	Counters.Counter private tokenIds;

	string private _baseURI;
	uint256 private _revealedTill;

	uint256 public cap;

	event SetCap(uint256 _cap);

	constructor(uint256 _cap) {
		setCap(_cap);
	}

	/**
	 * @notice - Mint NFT
	 * @dev - callable only by admin
	 *
	 * @param recipient - mint to
	 * @param URI - uri of the NFT
	 */
	function mint(address recipient, string memory URI) external onlyAdmin returns (uint256) {
		tokenIds.increment();
		uint256 newTokenId = tokenIds.current();
		require(newTokenId <= cap, 'NFT cap exceeded');

		_mint(recipient, newTokenId);
		_setTokenURI(newTokenId, URI);
		return newTokenId;
	}

	/**
	 * @notice - Set URI for token
	 * @dev - callable only by admin
	 *
	 * @param tokenId - Token ID of NFT
	 * @param _tokenURI - URI to set
	 */
	function setURI(uint256 tokenId, string memory _tokenURI) external onlyAdmin {
		_setTokenURI(tokenId, _tokenURI);
	}

	function setCap(uint256 _cap) public onlyOwner {
		cap = _cap;
		emit SetCap(_cap);
	}

	/**
	 * @notice - Set URI for token batch
	 * @dev - callable only by admin
	 *
	 * @param _tokenIds - Token IDs of NFTs
	 * @param tokenURIs - URIs to set
	 */
	function setBatchURI(uint256[] memory _tokenIds, string[] memory tokenURIs) external onlyAdmin {
		require(_tokenIds.length == tokenURIs.length, 'Length mismatch');
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			_setTokenURI(_tokenIds[i], tokenURIs[i]);
		}
	}

	function baseURIForReveals() public view virtual returns (string memory) {
		return _baseURI;
	}

	function setBaseURI(string memory __baseURI) external onlyAdmin {
		_baseURI = __baseURI;
	}

	function setRevealedTill(uint256 __revealedTill) external onlyAdmin {
		_revealedTill = __revealedTill;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

		if (tokenId > _revealedTill || bytes(_baseURI).length == 0) {
			return super.tokenURI(tokenId);
		}
		return string(abi.encodePacked(_baseURI, tokenId.toString()));
	}

	function setTokenURIBatch(uint256[] memory _tokenIds, string[] memory tokenURIs) external onlyAdmin {
		require(_tokenIds.length == tokenURIs.length, 'Length mismatch');
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			_setTokenURI(_tokenIds[i], tokenURIs[i]);
		}
	}
}