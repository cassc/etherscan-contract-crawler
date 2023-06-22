//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IXNftURI.sol";
import "../interfaces/IXanaliaAddressesStorage.sol";

contract XNFT is ERC721, Ownable, ERC721URIStorage {
	using SafeMath for uint256;
	using Counters for Counters.Counter;

	Counters.Counter public tokenId;
	IXanaliaAddressesStorage public xanaliaAddressesStorage;

	uint256 public constant MAX_ROYALTY_FEE = 1000;
	address public contractAuthorAddress;

	mapping(uint256 => address) public creators;
	mapping(uint256 => uint256) public royaltyFee;
	mapping(uint256 => string) public tokenURIs;

	constructor(
		string memory _name,
		string memory _symbol,
		address _author,
		address _xanaliaAddressesStorage
	) ERC721(_name, _symbol) {
		contractAuthorAddress = _author;
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
		transferOwnership(xanaliaAddressesStorage.xanaliaDex());
	}

	function _burn(uint256 _tokenId) internal virtual override(ERC721, ERC721URIStorage) {
		super._burn(_tokenId);
	}

	function _baseURI() internal view override returns (string memory) {
		return IXNftURI(xanaliaAddressesStorage.xNftURI()).baseMetadataURI();
	}

	function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
		return string(abi.encodePacked(_baseURI(), tokenURIs[_tokenId]));
	}

	/**
	 * @dev Create new NFT
	 * @param _royaltyFee of tokenID
	 */
	function create(
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _owner
	) external onlyOwner returns (uint256) {
		require(_royaltyFee <= MAX_ROYALTY_FEE, "Max-royalty-fee-is-10%");
		tokenId.increment();
		uint256 newTokenId = tokenId.current();
		_mint(_owner, newTokenId);
		creators[newTokenId] = _owner;
		royaltyFee[newTokenId] = _royaltyFee;
		tokenURIs[newTokenId] = _tokenURI;
		return newTokenId;
	}

	/**
	 * @dev calculates the next token ID based on value of _currentTokenId
	 * @return uint256 for the next token ID
	 */
	function _getNextTokenId() private view returns (uint256) {
		return tokenId.current().add(1);
	}

	function getCreator(uint256 _id) public view returns (address) {
		return creators[_id];
	}

	function getContractAuthor() public view returns (address) {
		return contractAuthorAddress;
	}

	function getRoyaltyFee(uint256 _id) public view returns (uint256) {
		return royaltyFee[_id];
	}

	function setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) external onlyOwner {
		require(owner != operator, "ERC721: approve to caller");
		_setApprovalForAll(owner, operator, approved);
	}
}