// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract FanStation_NFT is ERC721URIStorage, ERC721Enumerable, ERC165Storage, Ownable {
	
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	address public creator;
	string public version = "0.1.1";

	constructor() ERC721("FanStation NFT", "FanStation_NFT") {
		creator = msg.sender;
		_registerInterface(_INTERFACE_ID_ERC2981);
	}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    	super._beforeTokenTransfer(from, to, tokenId);
    }

	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		ERC721URIStorage._burn(tokenId);
	}

	function burn(uint256 tokenId) public {
		require(msg.sender == owner(), "This operation can only be performed by the contract owner");
		_burn(tokenId);
	}

	/**
	 * Returns roylaties information as proposed by Foundation contracts; see  
	 * https://etherscan.io/address/0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405.
	 * tokenId is ignored as all tokens in this contract share the same 
	 * royalties definitions.
	 * 
	 * For more information on allocating memory arrays, see:
	 * https://docs.soliditylang.org/en/v0.8.5/types.html#allocating-memory-arrays
	 */

	function getRoyalties(uint256 tokenId) public view returns(address[] memory, uint[] memory) {
		require(tokenId >= 0, "Prevent 'unused function parameter' warning");

		address[] memory royaltiesRecipients = new address[](1);
		royaltiesRecipients[0] = owner();

		uint[] memory royaltiesRecipientsFeeBasisPoints = new uint[](1);
		royaltiesRecipientsFeeBasisPoints[0] = 15000;

		return (royaltiesRecipients, royaltiesRecipientsFeeBasisPoints);
	}

	/**
	 * Returns Roylaties information as proposed by EIP-2981. see 
	 * -- see https://eips.ethereum.org/EIPS/eip-2981. tokenId is ignored as all
	 * tokens in this contract share the same royalties definitions.
	 */

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    	require(tokenId >= 0, "Prevent 'unused function parameter' warning");
    	return (owner(), (salePrice/100) * 5);
    }

	function safeMint(uint256 tokenId, string memory tokenURI_) public {
		require(msg.sender == owner(), "This operation can only be performed by the contract owner");
		_safeMint(msg.sender, tokenId);
		_setTokenURI(tokenId, tokenURI_);
	}

	function setTokenURI(uint256 tokenId, string calldata tokenURI_) public {
		require(msg.sender == owner(), "This operation can only be performed by the contract owner");
		_setTokenURI(tokenId, tokenURI_);
	}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC165Storage) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    	return ERC721URIStorage.tokenURI(tokenId);
    }

}