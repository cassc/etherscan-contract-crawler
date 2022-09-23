// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "ERC721A/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract ERC721ABase is ERC721A, Ownable, Pausable, ERC2981 {
	string private baseURI;

	constructor(
		string memory name,
		string memory symbol,
		string memory baseURI_,
		address payable royaltyRecipient,
		uint96 royaltyBPS
	) ERC721A(name, symbol) {
		_setDefaultRoyalty(royaltyRecipient, royaltyBPS);
		baseURI = baseURI_;
	}

	modifier tokenExists(uint256 tokenId) {
		require(ERC721A._exists(tokenId), "ERC721ABase: token does not exist");
		_;
	}

	modifier onlyApprovedOrOwner(uint256 tokenId) {
		require(
			_ownershipOf(tokenId).addr == _msgSender() ||
				getApproved(tokenId) == _msgSender(),
			"ERC721ABase: caller is not owner nor approved"
		);
		_;
	}

	function setBaseURI(string memory baseURI_) external onlyOwner {
		baseURI = baseURI_;
	}

	function _beforeTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal virtual override {
		require(!paused(), "ERC721ABase: token transfer while paused");
		super._beforeTokenTransfers(from, to, startTokenId, quantity);
	}

	// @notice: Overrides _startTokenId in ERC721A
	function _startTokenId() internal pure virtual override returns (uint256) {
		return 1;
	}

	// @notice Overrides _baseURI() in ERC721A
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	// @notice Overrides supportsInterface as required by inheritance.
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721A, ERC2981)
		returns (bool)
	{
		return
			ERC721A.supportsInterface(interfaceId) ||
			ERC2981.supportsInterface(interfaceId);
	}

	function setDefaultRoyalty(address receiver, uint96 basisPoints)
		public
		virtual
		onlyOwner
	{
		_setDefaultRoyalty(receiver, basisPoints);
	}

	/// @notice Pauses the contract.
	function pause() public onlyOwner {
		Pausable._pause();
	}

	/// @notice Unpauses the contract.
	function unpause() public onlyOwner {
		Pausable._unpause();
	}
}