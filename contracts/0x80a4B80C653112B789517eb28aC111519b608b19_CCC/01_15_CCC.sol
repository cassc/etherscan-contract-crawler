// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CCC is ERC721Enumerable, Ownable, ReentrancyGuard {
	using Strings for uint256;

	//this will be modified according to various gamifications
	string private _baseTokenURI = "ipfs://QmdzzEnRVcK4BbQ4hpEaCH8KNSzwFWNxQgPwbEkTeGmRiP/";
	string private _contractURI = "ipfs://QmdDS6Cro5MnPqubZFaQYvEzXjfUpVJnRGPsH8ufxTpi24";

	//toggle the sale
	bool public isSaleActive = false;

	//no more than 10k
	uint256 public constant totalTokenToMint = 10000;

	//the enumerable part from ERC721Enumerable
	uint256 public tokenIndex = 0;

	//triggers on gamification event
	event CustomThing(uint256 nftID, uint256 value, uint256 actionID, string payload);

	constructor() ERC721("Crypto Cannabis Club", "CCC") {}

	/*
	 * This is how you get one, or more...
	 */
	function acquire(uint256 amount) public payable nonReentrant {
		require(amount > 0, "minimum 1 token");
		require(amount <= totalTokenToMint - tokenIndex, "greater than max supply");
		require(isSaleActive, "sale is not active");
		require(amount <= 20, "max 20 tokens at once");
		require(getPricePerToken() * amount == msg.value, "exact value in ETH needed");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	//in case tokens are not sold, admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 amount) public onlyOwner {
		require(amount > 0, "minimum 1 token");
		require(amount <= totalTokenToMint - tokenIndex, "amount is greater than the token available");
		for (uint256 i = 0; i < amount; i++) {
			_mintToken(_msgSender());
		}
	}

	/*
	 * Internal mint function
	 */
	function _mintToken(address destinationAddress) private {
		tokenIndex++;
		require(!_exists(tokenIndex), "Token already exist.");
		_safeMint(destinationAddress, tokenIndex);
	}

	/*
	 * Calculate price for the immediate next NFT minted
	 */
	function getPricePerToken() public view returns (uint256) {
		require(isSaleActive, "sale is not active");
		require(totalSupply() < totalTokenToMint, "we're at max supply");
		return 70000000000000000; // 0.07 ETH
	}

	/*
	 * Custom thing
	 */
	function customThing(
		uint256 nftID,
		uint256 id,
		string memory what
	) external payable {
		require(isSaleActive, "sale is not active");
		require(ownerOf(nftID) == msg.sender, "NFT ownership required");
		emit CustomThing(nftID, msg.value, id, what);
	}

	/*
	 * Helper function
	 */
	function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			// Return an empty array
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	/*
	 * Burn...
	 */
	function burn(uint256 tokenId) public virtual {
		require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
		_burn(tokenId);
	}

	function exists(uint256 _tokenId) external view returns (bool) {
		return _exists(_tokenId);
	}

	function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
		return _isApprovedOrOwner(_spender, _tokenId);
	}

	function stopSale() external onlyOwner {
		isSaleActive = false;
	}

	function startSale() external onlyOwner {
		isSaleActive = true;
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function reclaimERC20(IERC20 erc20Token) public onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}