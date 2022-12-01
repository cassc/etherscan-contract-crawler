// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorldCupNFT is Ownable, ERC721Enumerable {
	using Address for address;
	using Strings for uint;

	struct CardInfo {
		uint cardId;
		string name;
		uint currentAmount;
		uint burnedAmount;
		uint maxAmount;
		string tokenURI;
	}

	uint public burned;
	uint public currentId;
	string public myBaseURI;
	address public superMinter;
	mapping(address => mapping(uint => uint)) public minters;
	mapping(uint => CardInfo) public cardInfoes; // cardId   =>
	mapping(uint => uint) public cardIdMap; // tokenId  =>

	constructor(
		string memory name_,
		string memory symbol_,
		string memory myBaseURI_
	) ERC721(name_, symbol_) {
		myBaseURI = myBaseURI_;
		currentId = 1;
	}

	function setMyBaseURI(string calldata uri_) public onlyOwner {
		myBaseURI = uri_;
	}

	function newCard(
		string calldata name_,
		uint cardId_,
		uint maxAmount_,
		string calldata tokenURI_
	) public onlyOwner {
		require(cardId_ != 0 && cardInfoes[cardId_].cardId == 0, "K: wrong cardId");

		cardInfoes[cardId_] = CardInfo({ cardId: cardId_, name: name_, currentAmount: 0, burnedAmount: 0, maxAmount: maxAmount_, tokenURI: tokenURI_ });
	}

	function editCard(
		string calldata name_,
		uint cardId_,
		uint curAmount_,
		uint burnAmount_,
		uint maxAmount_,
		string calldata tokenURI_
	) public onlyOwner {
		require(cardId_ != 0 && cardInfoes[cardId_].cardId == cardId_, "K: wrong cardId");

		cardInfoes[cardId_] = CardInfo({
			cardId: cardId_,
			name: name_,
			currentAmount: curAmount_,
			burnedAmount: burnAmount_,
			maxAmount: maxAmount_,
			tokenURI: tokenURI_
		});
	}

	function setSuperMinter(address newSuperMinter_) public onlyOwner returns (bool) {
		superMinter = newSuperMinter_;
		return true;
	}

	function setMinterBatch(
		address newMinter_,
		uint[] calldata ids_,
		uint[] calldata amounts_
	) public onlyOwner returns (bool) {
		require(ids_.length > 0 && ids_.length == amounts_.length, "ids and amounts length mismatch");
		for (uint i = 0; i < ids_.length; ++i) {
			minters[newMinter_][ids_[i]] = amounts_[i];
		}
		return true;
	}

	function mint(address player_, uint cardId_) public returns (uint) {
		require(cardId_ != 0 && cardInfoes[cardId_].cardId != 0, "K: wrong cardId");

		if (superMinter != _msgSender()) {
			require(minters[_msgSender()][cardId_] > 0, "K: not minter");
			minters[_msgSender()][cardId_] -= 1;
		}

		require(cardInfoes[cardId_].currentAmount < cardInfoes[cardId_].maxAmount, "k: amount out of limit");
		cardInfoes[cardId_].currentAmount += 1;

		uint tokenId = currentId;
		currentId++;
		cardIdMap[tokenId] = cardId_;
		_safeMint(player_, tokenId);

		return tokenId;
	}

	function mintMulti(
		address player_,
		uint cardId_,
		uint amount_
	) public returns (uint[] memory tokenIds) {
		require(amount_ > 0, "K: missing amount");
		require(cardId_ != 0 && cardInfoes[cardId_].cardId != 0, "K: wrong cardId");

		if (superMinter != _msgSender()) {
			require(minters[_msgSender()][cardId_] >= amount_, "K: not minter");
			minters[_msgSender()][cardId_] -= amount_;
		}

		require(cardInfoes[cardId_].maxAmount - cardInfoes[cardId_].currentAmount >= amount_, "K: amount out of limit");
		cardInfoes[cardId_].currentAmount += amount_;

		tokenIds = new uint[](amount_);
		uint tokenId = currentId;
		for (uint i = 0; i < amount_; ++i) {
			cardIdMap[tokenId] = cardId_;
			_safeMint(player_, tokenId);
			tokenIds[i] = tokenId;
			tokenId++;
		}
		currentId = tokenId;
	}

	function mintBatch(
		address player_,
		uint[] calldata ids_,
		uint[] calldata amounts_
	) public returns (bool) {
		require(ids_.length > 0 && ids_.length == amounts_.length, "length mismatch");
		for (uint i = 0; i < ids_.length; ++i) {
			mintMulti(player_, ids_[i], amounts_[i]);
		}
		return true;
	}

	function burn(uint tokenId_) public returns (bool) {
		require(_isApprovedOrOwner(_msgSender(), tokenId_), "K: burner isn't owner");
		uint cardId = cardIdMap[tokenId_];
		cardInfoes[cardId].burnedAmount += 1;
		burned += 1;

		_burn(tokenId_);
		return true;
	}

	function burnMulti(uint[] calldata tokenIds_) public returns (bool) {
		for (uint i = 0; i < tokenIds_.length; ++i) {
			burn(tokenIds_[i]);
		}
		return true;
	}

	function tokenURI(uint tokenId_) public view override returns (string memory) {
		require(_exists(tokenId_), "K: nonexistent token");
		string memory cURI = cardInfoes[cardIdMap[tokenId_]].tokenURI;
		return string(abi.encodePacked(myBaseURI, cURI));
	}

	function batchTokenInfo(address account_)
		public
		view
		returns (
			uint[] memory cIdInfo,
			uint[] memory tIdInfo,
			string[] memory uriInfo
		)
	{
		uint amount = balanceOf(account_);
		uint tokenId;
		cIdInfo = new uint[](amount);
		tIdInfo = new uint[](amount);
		uriInfo = new string[](amount);
		for (uint i = 0; i < amount; i++) {
			tokenId = tokenOfOwnerByIndex(account_, i);
			cIdInfo[i] = cardIdMap[tokenId];
			tIdInfo[i] = tokenId;
			uriInfo[i] = tokenURI(tokenId);
		}
	}
}