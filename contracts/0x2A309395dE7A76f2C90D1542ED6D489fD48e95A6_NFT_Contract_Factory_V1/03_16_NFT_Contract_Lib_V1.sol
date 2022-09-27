// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.17;

abstract contract NFT_Contract_Lib_V1 is ERC721, Ownable, ERC721Enumerable {
	using SafeMath for uint256;
	using Strings for uint256;

	struct MinterStruct {
		uint256 val;
	}

	uint256 public cost;
	address payable public payments;
	uint256 public MAX_TOKENS;
	uint256 public perWalletLimit;
	uint256 public freeLimit;
	string public baseURI;

	bool public saleIsActive;
	bool public isPreSale;

	mapping(address => MinterStruct) public minters;
	mapping(address => bool) public preSaleList;

	event Minted(uint256 tokenId, address owner);

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setPerWalletLimit(uint256 _perWalletLimit) public onlyOwner {
		perWalletLimit = _perWalletLimit;
	}

	function setFreeLimit(uint256 _freeLimit) public onlyOwner {
		freeLimit = _freeLimit;
	}

	function setCost(uint256 _cost) public onlyOwner {
		cost = _cost;
	}

	function getMinters(address _minter) public returns(uint256) {
		return minters[_minter].val;
	}

	function addToPreSaleList(address[] calldata _participants) public onlyOwner {
		for(uint i = 0; i < _participants.length; i++) {
			preSaleList[_participants[i]] = true;
		}
	}

	function withdraw() public payable onlyOwner {
		(bool os, ) = payable(payments).call{ value: address(this).balance }("");
		require(os);
	}

	function togglePreSale() external onlyOwner {
		isPreSale = !isPreSale;
	}

	function toggleSale() external onlyOwner {
		saleIsActive = !saleIsActive;
	}

	function tokensOfOwner(address _owner)
	external
	view
	returns (uint256[] memory)
	{
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

	function mintNFT(uint256 numberOfTokens) public payable TokenLimitChecked(numberOfTokens) {
		if(!isPreSale) {
			require(saleIsActive, "Sale is not active");
			if(minters[msg.sender].val >= freeLimit && cost > 0) {
				require(msg.value >= cost * numberOfTokens);
				minters[msg.sender].val += numberOfTokens;
				for (uint256 i = 0; i < numberOfTokens; i++) {
					uint256 id = totalSupply().add(1);
					if (totalSupply() < MAX_TOKENS) {
						_safeMint(msg.sender, id);
						emit Minted(id, msg.sender);
					}
				}
			} else {
				minters[msg.sender].val += numberOfTokens;
				for (uint256 i = 0; i < numberOfTokens; i++) {
					uint256 id = totalSupply().add(1);
					if (totalSupply() < MAX_TOKENS) {
						_safeMint(msg.sender, id);
						emit Minted(id, msg.sender);
					}
				}
			}
		} else {
			require(
				preSaleList[msg.sender],
				"This address is not on the whitelist."
			);
			require(
				numberOfTokens > 0 && getMinters(msg.sender).add(numberOfTokens) <= perWalletLimit,
				"Max token limit for per wallet"
			);
			if(minters[msg.sender].val >= 1) {
				require(msg.value >= cost * numberOfTokens);
				minters[msg.sender].val += numberOfTokens;
				for (uint256 i = 0; i < numberOfTokens; i++) {
					uint256 id = totalSupply().add(1);
					if (totalSupply() < MAX_TOKENS) {
						_safeMint(msg.sender, id);
						emit Minted(id, msg.sender);
					}
				}
			} else {
				minters[msg.sender].val += numberOfTokens;
				for (uint256 i = 0; i < numberOfTokens; i++) {
					uint256 id = totalSupply().add(1);
					if (totalSupply() < MAX_TOKENS) {
						_safeMint(msg.sender, id);
						emit Minted(id, msg.sender);
					}
				}
			}
		}
	}

	modifier TokenLimitChecked (uint256 numberOfTokens) {
		require(
			numberOfTokens > 0 && numberOfTokens <= perWalletLimit,
			"Max token limit"
		);
		require(
			getMinters(msg.sender).add(numberOfTokens) <= perWalletLimit,
			"Max token limit for per wallet"
		);
		require(
			totalSupply().add(numberOfTokens) <= MAX_TOKENS,
			"Purchase would exceed max supply of tokens"
		);
		_;
	}

	function tokenURI(uint256 tokenId)
	public
	view
	virtual
	override
	returns (string memory)
	{
		require(
			_exists(tokenId),
			"ERC721Metadata: URI query for nonexistent token"
		);

		string memory currentBaseURI = _baseURI();

		return
		bytes(currentBaseURI).length > 0
		? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
		: "";

	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) {
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
}