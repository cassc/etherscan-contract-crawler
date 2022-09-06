// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PelosiNft is ERC721Enumerable, Ownable {
	using Strings for uint256;

	string public myBaseURI;
	address public superMinter;
	uint256 public _tokenIds;
	mapping(address => uint256) public minters;

	constructor(
		string memory name_,
		string memory symbol_,
		string memory myBaseURI_
	) ERC721(name_, symbol_) {
		myBaseURI = myBaseURI_;
	}

	// ---------------- onlyOwner ----------------

	function setMinter(address minter_, uint256 amount_) public onlyOwner {
		minters[minter_] = amount_;
	}

	function setSuperMinter(address newSuperMinter_) public onlyOwner {
		superMinter = newSuperMinter_;
	}

	function setMyBaseURI(string memory uri_) public onlyOwner {
		myBaseURI = uri_;
	}

	// ---------------- onlyOwner end ----------------

	function mint(address account_) public returns (uint256) {
		if (superMinter != _msgSender()) {
			require(minters[_msgSender()] >= 1, "not minter");
			minters[_msgSender()] -= 1;
		}
		uint256 tokenId = _tokenIds;
		_tokenIds++;
		_safeMint(account_, tokenId);
		return tokenId;
	}

	function burn(uint256 tokenId_) public returns (bool) {
		require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721: burn caller is not owner nor approved");

		_burn(tokenId_);
		return true;
	}

	function burnMulti(uint256[] calldata tokenIds_) public returns (bool) {
		for (uint256 i = 0; i < tokenIds_.length; ++i) {
			uint256 tokenId_ = tokenIds_[i];
			require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721: burn caller is not owner nor approved");

			_burn(tokenId_);
		}
		return true;
	}

	function tokenURI(uint256 tokenId_) public view override returns (string memory) {
		require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");

		return string(abi.encodePacked(_baseURI(), "/", tokenId_.toString()));
	}

	function _baseURI() internal view override returns (string memory) {
		return myBaseURI;
	}

	function batchTokenURI(address account_) public view returns (uint256[] memory tIdInfo, string[] memory uriInfo) {
		uint256 amount = balanceOf(account_);
		uint256 tokenId;
		tIdInfo = new uint256[](amount);
		uriInfo = new string[](amount);
		for (uint256 i = 0; i < amount; i++) {
			tokenId = tokenOfOwnerByIndex(account_, i);
			tIdInfo[i] = tokenId;
			uriInfo[i] = tokenURI(tokenId);
		}
	}
}