// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC721AntiScam.sol";
import "./lockable/ERC721Lockable.sol";
import "./restrictApprove/ERC721RestrictApprove.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title AntiScam機能付きERC721A
/// @dev Readmeを見てください。

abstract contract ERC721AntiScam is IERC721AntiScam, ERC721Lockable, ERC721RestrictApprove, Ownable {
	/*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

	function isApprovedForAll(
		address owner,
		address operator
	) public view virtual override(ERC721Lockable, ERC721RestrictApprove) returns (bool) {
		if (isLocked(owner) || !_isAllowed(owner, operator)) {
			return false;
		}
		return super.isApprovedForAll(owner, operator);
	}

	function setApprovalForAll(
		address operator,
		bool approved
	) public virtual override(ERC721Lockable, ERC721RestrictApprove) {
		require(isLocked(msg.sender) == false || approved == false, "Can not approve locked token");
		require(_isAllowed(operator) || approved == false, "RestrictApprove: Can not approve locked token");
		super.setApprovalForAll(operator, approved);
	}

	function _beforeApprove(
		address to,
		uint256 tokenId
	) internal virtual override(ERC721Lockable, ERC721RestrictApprove) {
		ERC721Lockable._beforeApprove(to, tokenId);
		ERC721RestrictApprove._beforeApprove(to, tokenId);
	}

	function approve(address to, uint256 tokenId) public payable virtual override(ERC721Lockable, ERC721RestrictApprove) {
		_beforeApprove(to, tokenId);
		ERC721A.approve(to, tokenId);
	}

	function _beforeTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal virtual override(ERC721A, ERC721Lockable) {
		ERC721Lockable._beforeTokenTransfers(from, to, startTokenId, quantity);
	}

	function _afterTokenTransfers(
		address from,
		address to,
		uint256 startTokenId,
		uint256 quantity
	) internal virtual override(ERC721Lockable, ERC721RestrictApprove) {
		ERC721Lockable._afterTokenTransfers(from, to, startTokenId, quantity);
		ERC721RestrictApprove._afterTokenTransfers(from, to, startTokenId, quantity);
	}

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(ERC721Lockable, ERC721RestrictApprove) returns (bool) {
		return
			ERC721A.supportsInterface(interfaceId) ||
			ERC721Lockable.supportsInterface(interfaceId) ||
			ERC721RestrictApprove.supportsInterface(interfaceId) ||
			interfaceId == type(IERC721AntiScam).interfaceId;
	}
}