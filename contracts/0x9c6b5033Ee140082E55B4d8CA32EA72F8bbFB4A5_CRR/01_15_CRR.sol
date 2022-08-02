// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CRR is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;

	// IPFS URI of BASE that has all nft metadata in it
	string public BASE_URI = "https://ipfs.io/ipfs/QmPnoCtuczBRFVmn7kjpa44zyG6ALDHMAQAK3ZdecWvxHM/";

	uint256 public constant MAX_SUPPLY = 111;

    uint256 public salePrice = 0.2 ether;
	
	// Ideally, you would pass in some sort of unique identifier to reference your token
	// for this demo we're just repurposing the token URI
	mapping(uint256 => uint256) public _uriId;
	
	constructor() ERC721("Crazy Rich Rabbit", "CRR") {

		/// @notice mint 111 NFTs at once when deployed
		for(uint i=0; i<111; i++) {
			_mint(msg.sender, i);

			/// @notice token json file name of newly minted NFT metadata 
			string memory _tokenJsonName = string.concat(Strings.toString(i), ".json");
			_setTokenURI(i, _tokenJsonName);

			_uriId[i] = i + 1;
		}
	}

	// Set Sale Price
    function setSalePrice(uint256 price) external onlyOwner {
        salePrice = price;
    }
	
	function CustomMint(uint256 tokenid) public payable returns (uint256) {

		string memory _uri=".json";
		_uri = string.concat(Strings.toString(tokenid), _uri);
		
		// Check for a token that already exists
		require(_uriId[tokenid] == 0, "This key is already minted.");
		require(msg.value >= salePrice, "Price is less than salePrice.");
		
		_tokenIds.increment();
		uint256 newItemId = _tokenIds.current();

		// Call the OpenZepplin mint function
		_safeMint(msg.sender, newItemId);
		// Record the URI and it's associated token id for quick lookup
		_uriId[tokenid] = newItemId;
		// Store the URI in the token
		_setTokenURI(newItemId, _uri);

		return newItemId;
	}

    // // metadata URI
    // string private baseTokenURI;

	function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

	function setBaseURI(string calldata baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }
	
	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
	}
	
	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
		internal
		override(ERC721, ERC721Enumerable)
	{
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
	
	function tokenURI(uint256 tokenId)
		public
		view
		override(ERC721, ERC721URIStorage)
		returns (string memory)
	{
		return super.tokenURI(tokenId);
	}
	
	function tokenByUri(uint256 tokenid) external view returns(uint256) {		
		return _uriId[tokenid];
	}

	function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
		uint256 tokenCount = balanceOf(_owner);

		if (tokenCount == 0) {
			// Return an empty array
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 totalKeys = totalSupply();
			uint256 resultIndex = 0;

			// We count on the fact that all tokens have IDs starting at 1 and increasing
			// sequentially up to the totalSupply count.
			uint256 tokenId;

			for (tokenId = 1; tokenId <= totalKeys; tokenId++) {
				if (ownerOf(tokenId) == _owner) {
					result[resultIndex] = tokenId;
					resultIndex++;
				}
			}

			return result;
		}
	}

	function mintedNFTs() external view returns(uint256[] memory nfts) {
		uint256 tokenCount = MAX_SUPPLY;

		if (tokenCount == 0) {
			// Return an empty array
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 resultIndex = 0;

			// We count on the fact that all tokens have IDs starting at 1 and increasing
			// sequentially up to the totalSupply count.
			uint256 tokenId;

			for (tokenId = 0; tokenId < tokenCount; tokenId++) {
				if (_uriId[tokenId] == 0) {
					result[resultIndex] = tokenId + 1;
					resultIndex++;
				}
			}

			return result;
		}
	}
}