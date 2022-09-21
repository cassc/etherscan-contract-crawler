// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SimpleCollectible is ERC721URIStorage {
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;
	uint256 public maxSupply = 1000;

	constructor() ERC721("Dicer", "Dicer") {}

	function createCollectible(address owner, string memory tokenURI)
		public
		returns (uint256)
	{
		require(_tokenIds.current() < maxSupply, "MAX SUPPLY EXCEEDED");

		uint256 newItemId = _tokenIds.current();

		_mint(owner, newItemId);
		_setTokenURI(newItemId, tokenURI);

		_tokenIds.increment();
		return newItemId;
	}
}