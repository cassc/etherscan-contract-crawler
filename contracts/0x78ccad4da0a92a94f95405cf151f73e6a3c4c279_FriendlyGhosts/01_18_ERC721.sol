// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract FriendlyGhosts is
	IERC721Metadata,
	ERC721Enumerable,
	AccessControlEnumerable
{
	bytes32 public constant SETUP = keccak256('SETUP');
	bytes32 public constant WITHDRAW = keccak256('WITHDRAW');

	uint16 public maxSupply;
	uint256 public price;
	bool public isMintActive;

	string private baseTokenURI;

	mapping(address => uint16) public reservers;
	bool[32] public reservedTokens;

	uint16 public currentId;

	struct ReservePair {
		address addr;
		uint16 id;
	}

	constructor(
		string memory name,
		string memory symbol,
		string memory baseUrl,
		uint16 _maxSupply,
		uint256 _price
	) ERC721(name, symbol) {
		maxSupply = _maxSupply;
		baseTokenURI = baseUrl;
		price = _price;

		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(SETUP, msg.sender);
		_setupRole(WITHDRAW, msg.sender);
	}

	function mint() external payable {
		require(isMintActive, 'Mint is not active');

		uint256 maxPerTx = 20;

		uint16 reservedTokenId = reservers[msg.sender];
		if (reservedTokenId != 0) {
			_mint(msg.sender, reservedTokenId);
			delete reservers[msg.sender];
			maxPerTx--;
		}

		uint256 amount = msg.value / price;

		require(amount <= maxPerTx, 'No more than 20 per transaction');
		require(currentId + amount <= maxSupply, 'Insufficient token amount');

		for (uint256 i = 0; i < amount; i++) {
			while (currentId < 32 && reservedTokens[currentId]) {
				currentId++;
			}

			_mint(msg.sender, currentId);
			currentId++;
		}
	}

	function setReserved(ReservePair[] memory _list) public onlyRole(SETUP) {
		for (uint16 i = 0; i < _list.length; i++) {
			ReservePair memory item = _list[i];

			reservers[item.addr] = item.id;
			reservedTokens[item.id] = true;
		}
	}

	function withdrawNative() external onlyRole(WITHDRAW) {
		payable(msg.sender).transfer(address(this).balance);
	}

	function withdrawERC20(address tokenAddr) external onlyRole(WITHDRAW) {
		IERC20 token = IERC20(tokenAddr);

		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

	function setBaseURI(string memory newBaseTokenURL)
		external
		onlyRole(SETUP)
	{
		baseTokenURI = newBaseTokenURL;
	}

	function setPrice(uint256 newPrice) external onlyRole(SETUP) {
		price = newPrice;
	}

	function setMintState(bool newMintState) external onlyRole(SETUP) {
		isMintActive = newMintState;
	}

	function _baseURI() internal view override returns (string memory) {
		return baseTokenURI;
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(AccessControlEnumerable, ERC721Enumerable, IERC165)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}

	receive() external payable {}
}