// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MoonRugsNFT is ERC721Enumerable, ContextMixin, NativeMetaTransaction, Ownable, ReentrancyGuard {
	
	using Strings for uint256;

	constructor() ERC721("MoonRugsNFT", "MRNFT") {}

	uint256 private constant MAX_MINTABLE = 10;
	uint256 private constant TOTAL_TOKENS = 10000;

	uint256[10000] private _availableTokens;
	uint256 private _numAvailableTokens = 10000;
	uint256 private tokenPrice = 0;
	
	address private proxyRegistryAddress = address(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

	mapping(address => uint256) private _addressMinted;

	function mint(uint256 _numToMint) external payable nonReentrant() {
		require(block.timestamp > 1660696969, "Sale hasn't started.");	
		require(msg.sender == tx.origin, "Contracts cannot mint");
		require(msg.sender != address(0), "ERC721: mint to the zero address");	
		require(_numToMint > 0, "ERC721r: need to mint at least one token");
		uint256 totalSupply = totalSupply();
		require(
			totalSupply + _numToMint <= TOTAL_TOKENS,
			"There aren't this many left."
		);
		require(_addressMinted[msg.sender] + _numToMint <= MAX_MINTABLE, "Minting to many.");
		uint256 costForMinting = tokenPrice * _numToMint; 
		require(
			msg.value >= costForMinting,
			"Too little sent, please send more eth."
		);
		if (msg.value > costForMinting) {
			payable(msg.sender).transfer(msg.value - costForMinting);
		}

		_addressMinted[msg.sender] += _numToMint;
		_mint(_numToMint);
	}

	// internal minting function
	function _mint(uint256 _numToMint) internal {
		uint256 updatedNumAvailableTokens = _numAvailableTokens;
		for (uint256 i = 0; i < _numToMint; i++) {
			uint256 newTokenId = useRandomAvailableToken(_numToMint, i);
			_safeMint(msg.sender, newTokenId);
			updatedNumAvailableTokens--;
		}
		_numAvailableTokens = updatedNumAvailableTokens;
	}

	function useRandomAvailableToken(uint256 _numToFetch, uint256 _i)
		internal
		returns (uint256)
	{
		uint256 randomNum =
			uint256(
				keccak256(
					abi.encode(
						msg.sender,
						tx.gasprice,
						block.number,
						block.timestamp,
						blockhash(block.number - 1),
						_numToFetch,
						_i
					)
				)
			);
		uint256 randomIndex = randomNum % _numAvailableTokens;
		return useAvailableTokenAtIndex(randomIndex);
	}

	function useAvailableTokenAtIndex(uint256 indexToUse)
		internal
		returns (uint256)
	{
		uint256 valAtIndex = _availableTokens[indexToUse];
		uint256 result;
		if (valAtIndex == 0) {
			// This means the index itself is still an available token
			result = indexToUse;
		} else {
			// This means the index itself is not an available token, but the val at that index is.
			result = valAtIndex;
		}

		uint256 lastIndex = _numAvailableTokens - 1;
		if (indexToUse != lastIndex) {
			// Replace the value at indexToUse, now that it's been used.
			// Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
			uint256 lastValInArray = _availableTokens[lastIndex];
			if (lastValInArray == 0) {
				// This means the index itself is still an available token
				_availableTokens[indexToUse] = lastIndex;
			} else {
				// This means the index itself is not an available token, but the val at that index is.
				_availableTokens[indexToUse] = lastValInArray;
			}
		}

		_numAvailableTokens--;
		return result;
	}

	function tokensOfOwner(address _owner)
		public
		view
		returns (uint256[] memory)
	{
		uint256 numTokens = balanceOf(_owner);
		if (numTokens == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](numTokens);
			for (uint256 i = 0; i < numTokens; i++) {
				result[i] = tokenOfOwnerByIndex(_owner, i);
			}
			return result;
		}
	}
	
	/*
	 * Dev stuff.
	 */

	// metadata URI
	string private _baseTokenURI;

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		string memory base = _baseURI();
		string memory _tokenURI = Strings.toString(_tokenId);

		// If there is no base URI, return the token URI.
		if (bytes(base).length == 0) {
			return _tokenURI;
		}

		return string(abi.encodePacked(base, _tokenURI));
	}
	
	/*
	 * Owner stuff
	 */

	function setBaseURI(string memory baseURI) external onlyOwner {
		_baseTokenURI = baseURI;
	}
	
	function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
		tokenPrice = _tokenPrice * 1e18;
	}

	function setProxyAddress(address _proxyRegistryAddress) external onlyOwner {
		proxyRegistryAddress = _proxyRegistryAddress;
	}

	function withdrawMoney() public payable onlyOwner {
		(bool success, ) = msg.sender.call{value: address(this).balance}("");
		require(success, "Transfer failed.");
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override(ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
	
	/**
	 * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
	 */
	function isApprovedForAll(address owner, address operator)
		override (ERC721, IERC721)
		public
		view
		returns (bool)
	{
		// Whitelist OpenSea proxy contract for easy trading.
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner, operator);
	}

	/**
	 * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
	 */
	function _msgSender()
		internal
		override
		view
		returns (address sender)
	{
		return ContextMixin.msgSender();
	}
}