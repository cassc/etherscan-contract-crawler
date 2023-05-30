// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721EnumerableNameable is ERC721Enumerable, Ownable {

	uint256 public nameChangePrice = 500 ether;
	uint256 public bioChangePrice = 500 ether;

	mapping (uint256 => string) private _tokenName;
	mapping (string => bool) private _nameReserved;
	mapping (uint256 => string) private _tokenBio;

	event NameChange (uint256 indexed tokenId, string newName);
	event BioChange (uint256 indexed tokenId, string bio);

	constructor(string memory _name, string memory _symbol) ERC721 (_name, _symbol) {}

	function changeName(uint256 tokenId, string memory newName) public virtual {
		address owner = ownerOf(tokenId);

		require(_msgSender() == owner, "You do not own this token.");
		require(validateName(newName) == true, "Invalid name.");
		require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one.");
		require(isNameReserved(newName) == false, "Name already reserved.");

		// If already named, dereserve old name
		if (bytes(_tokenName[tokenId]).length > 0) {
			toggleReserveName(_tokenName[tokenId], false);
		}
		toggleReserveName(newName, true);
		_tokenName[tokenId] = newName;
		emit NameChange(tokenId, newName);
	}

	function changeBio(uint256 _tokenId, string memory _bio) public virtual {
		address owner = ownerOf(_tokenId);
		require(_msgSender() == owner, "You do not own this token.");

		_tokenBio[_tokenId] = _bio;
		emit BioChange(_tokenId, _bio); 
	}

	function toggleReserveName(string memory str, bool isReserve) internal {
		_nameReserved[toLower(str)] = isReserve;
	}

	function tokenNameByIndex(uint256 index) public view returns (string memory) {
		return _tokenName[index];
	}

	function tokenBioByIndex(uint256 index) public view returns (string memory) {
		return _tokenBio[index];
	}

	function isNameReserved(string memory nameString) public view returns (bool) {
		return _nameReserved[toLower(nameString)];
	}

	function validateName(string memory str) public pure returns (bool){
		bytes memory b = bytes(str);
		if(b.length < 1) return false;
		if(b.length > 25) return false;
		if(b[0] == 0x20) return false;
		if (b[b.length - 1] == 0x20) return false;

		bytes1 lastChar = b[0];

		for(uint i; i<b.length; i++){
			bytes1 char = b[i];

			if (char == 0x20 && lastChar == 0x20) return false;

			if(
				!(char >= 0x30 && char <= 0x39) && 
				!(char >= 0x41 && char <= 0x5A) && 
				!(char >= 0x61 && char <= 0x7A) && 
				!(char == 0x20) 
			)
				return false;

			lastChar = char;
		}

		return true;
	}

	function toLower(string memory str) public pure returns (string memory){
		bytes memory bStr = bytes(str);
		bytes memory bLower = new bytes(bStr.length);
		for (uint i = 0; i < bStr.length; i++) {
			if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
				bLower[i] = bytes1(uint8(bStr[i]) + 32);
			} else {
				bLower[i] = bStr[i];
			}
		}
		return string(bLower);
	}
	
	function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
		virtual
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}