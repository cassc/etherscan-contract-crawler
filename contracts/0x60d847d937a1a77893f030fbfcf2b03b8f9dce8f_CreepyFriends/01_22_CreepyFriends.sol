// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Base classes
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import 'operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol';

// Upgradeability
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';

// Support utilities
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';

contract CreepyFriends is
	ERC721AUpgradeable,
	OwnableUpgradeable,
	DefaultOperatorFiltererUpgradeable,
	UUPSUpgradeable
{
	// This gap will allow us to add more upgradeable base classes; each one is 50 slots.
	uint256[500] private __gap;

	uint256 private _mintPrice;
	address private _mintSigningServerAddress;
	uint256 private _maxSupplyForMint;
	uint256 private _maxSupply;
	uint256 private _royalty;

	bool private _mintActive;
	bool private _paused;

	function initialize() external initializerERC721A initializer {
		__ERC721A_init('Creepy Friends', 'CREEP');

		__Ownable_init_unchained();
		__DefaultOperatorFilterer_init();

		_setToDefaultSettings();
	}

	// Contract settings

	function _setToDefaultSettings() private {
		_mintPrice = 0.05 ether;
		_mintSigningServerAddress = 0xE35E09660dB8cA8f60D183A5Dc5E2bDFCa0123Ad;
		_maxSupplyForMint = 4800;
		_maxSupply = 5000;
		_royalty = 500;
	}

	function setToDefaultSettings() external onlyOwner {
		_setToDefaultSettings();
	}

	function setMintPrice(uint256 newValue) external onlyOwner {
		_mintPrice = newValue;
	}

	function setMintSigningServerAddress(address newValue) external onlyOwner {
		_mintSigningServerAddress = newValue;
	}

	function setMaxSupplyForMint(uint256 newValue) external onlyOwner {
		_maxSupplyForMint = newValue;
	}

	function setMaxSupply(uint256 newValue) external onlyOwner {
		_maxSupply = newValue;
	}

	function setRoyalty(uint256 newValue) external onlyOwner {
		_royalty = newValue;
	}

	// Minting logic

	function setMintActive(bool active)
		external
		onlyProxy // We can only enable minting on the proxy, to avoid accidentally creating a duplicate collection
	{
		_mintActive = active;
	}

	function mintActive() external view returns (bool) {
		return _mintActive;
	}

	function mint(
		bytes memory signature,
		uint256 amount,
		uint8 maxAmountForAddress
	) external payable {
		require(_mintActive, 'minting is disabled');
		verifyServerSignature(signature, msg.sender, maxAmountForAddress);

		require(
			_numberMinted(msg.sender) + amount <= maxAmountForAddress,
			'already minted max amount for wallet'
		);
		require(_totalMinted() + amount <= _maxSupplyForMint, 'Passed maximum supply');

		require(msg.value == amount * _mintPrice, 'not enough funds');

		require(!_paused, 'Contract transfers are paused');

		_mint(msg.sender, amount);

		payable(owner()).transfer(msg.value);
	}

	function verifyServerSignature(
		bytes memory signature,
		address userAddress,
		uint8 maxAmountForAddress
	) private view {
		bytes32 hashedMessage = keccak256(abi.encodePacked(userAddress, maxAmountForAddress));

		bytes32 messageDigest = ECDSAUpgradeable.toEthSignedMessageHash(hashedMessage);
		address recovered_serverAddress = ECDSAUpgradeable.recover(messageDigest, signature);

		require(recovered_serverAddress == _mintSigningServerAddress, 'invalid signature');
	}

	function teamMint(address to, uint256 amount)
		external
		onlyOwner // only owner can airdrop
	{
		require(_totalMinted() + amount <= _maxSupply, 'Passed maximum supply');

		_mint(to, amount);
	}

	function _startTokenId() internal pure override returns (uint256) {
		return 1;
	}

	// Token URI

	function _baseURI() internal pure override returns (string memory) {
		return 'https://token.creepyfriends.io/token/';
	}

	// Royalty

	function royaltyInfo(uint256, uint256 salePrice)
		external
		view
		returns (address receiver, uint256 royaltyAmount)
	{
		return (owner(), (salePrice * _royalty) / 10000);
	}

	// Pausing

	function pause() external onlyOwner {
		_paused = true;
	}

	function unpause() external onlyOwner {
		_paused = false;
	}

	function isPaused() external view returns (bool) {
		return _paused;
	}

	function _beforeTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal override {
		super._beforeTokenTransfers(from, to, startTokenId, quantity);

		require(!_paused, 'Contract transfers are paused');
	}

	// Upgradeabilitiy

	function _authorizeUpgrade(address newImplementation)
		internal
		override
		onlyOwner // onlyOwner is all the logic we need here
	{}

	// opreator-filter-registry implementation

	function setApprovalForAll(address operator, bool approved)
		public
		override
		onlyAllowedOperatorApproval(operator)
	{
		super.setApprovalForAll(operator, approved);
	}

	function approve(address operator, uint256 tokenId)
		public
		payable
		override
		onlyAllowedOperatorApproval(operator)
	{
		super.approve(operator, tokenId);
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override onlyAllowedOperator(from) {
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public payable override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public payable override onlyAllowedOperator(from) {
		super.safeTransferFrom(from, to, tokenId, data);
	}

	// Multi base classes needs

	function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
		return
			interfaceId == 0x2a55205a || // Royalty standard https://eips.ethereum.org/EIPS/eip-2981
			super.supportsInterface(interfaceId);
	}
}