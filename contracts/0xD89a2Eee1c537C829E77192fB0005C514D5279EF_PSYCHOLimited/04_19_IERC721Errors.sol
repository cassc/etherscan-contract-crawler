// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC721Errors {
	error NonApprovedNonOwner(
		bool _isApprovedForAll,
		address _getApproved,
		address _ownerOf,
		address _sender
	);

	error FromAddressNonOwner(address _from, address _ownerOf);

	error NonOwnerApproval(address _ownerOf, address _sender);

	error CannotApproveOwner(address _ownerOf, address _approved);

	error TransferToZeroAddress(address _from, address _to, uint256 _tokenId);

	error TransferToNonERC721Receiver(address _contract);

	error TxOriginNonSender(address _origin, address _sender);
}