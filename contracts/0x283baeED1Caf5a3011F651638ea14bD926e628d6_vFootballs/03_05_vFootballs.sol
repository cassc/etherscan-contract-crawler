// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract vFootballs is ERC721A, Ownable {
	enum SaleStatus {
		PAUSED,
		PUBLIC
	}

	uint256 public constant COLLECTION_SIZE = 5000;
	uint256 public constant TOKENS_PER_TRAN_LIMIT = 20;

	uint256 public MINT_PRICE = 0 ether;
	SaleStatus public saleStatus = SaleStatus.PUBLIC;

	string private _baseURL;
	string private _hiddenURI;
	mapping(address => uint256) private _mintedCount;

	constructor(string memory hiddenUri) ERC721A('vFootballs', 'vball') {
		_hiddenURI = hiddenUri;
	}

	/// @notice Reveal metadata for all the tokens
	function reveal(string memory uri) external onlyOwner {
		_baseURL = uri;
	}

	/// @dev override base uri. It will be combined with token ID
	function _baseURI() internal view override returns (string memory) {
		return _baseURL;
	}

	function _startTokenId() internal pure override returns (uint256) {
		return 1;
	}

	/// @notice Update current sale stage
	function setSaleStatus(SaleStatus status) external onlyOwner {
		saleStatus = status;
	}

	/// @notice Withdraw contract's balance
	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		require(balance > 0, 'vFootballs: No balance');

		payable(owner()).transfer(balance);
	}

	/// @notice Allows owner to mint tokens to a specified address
	function airdrop(address to, uint256 count) external onlyOwner {
		require(
			_totalMinted() + count <= COLLECTION_SIZE,
			'vFootballs: Request exceeds collection size'
		);
		_safeMint(to, count);
	}

	/// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
	/// @param tokenId token ID
	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory)
	{
		require(
			_exists(tokenId),
			'ERC721Metadata: URI query for nonexistent token'
		);

		return
			bytes(_baseURI()).length > 0
				? string(
					abi.encodePacked(_baseURI(), _toString(tokenId), '.json')
				)
				: _hiddenURI;
	}

	function calcTotal(uint256 count) public view returns (uint256) {
		require(saleStatus != SaleStatus.PAUSED, 'vFootballs: Sales are off');
		return count * MINT_PRICE;
	}

	/// @notice Mints specified amount of tokens
	/// @param count How manny tokens to mint
	function mint(uint256 count) external payable {
		require(saleStatus != SaleStatus.PAUSED, 'vFootballs: Sales are off');
		require(
			_totalMinted() + count <= COLLECTION_SIZE,
			'vFootballs: Number of requested tokens will exceed collection size'
		);
		require(
			count <= TOKENS_PER_TRAN_LIMIT,
			'vFootballs: Requested token count exceeds allowance (20)'
		);
		require(
			msg.value >= calcTotal(count),
			'vFootballs: Ether value sent is not sufficient'
		);
		_mintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}
}