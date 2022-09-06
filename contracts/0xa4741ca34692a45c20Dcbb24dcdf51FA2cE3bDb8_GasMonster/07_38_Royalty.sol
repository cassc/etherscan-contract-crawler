// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import './interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

///
/// @dev Interface for the NFT Royalty Standard
///
contract Royalty is IERC2981, ERC165 {
	/// ERC165 bytes to add to interface array - set in parent contract
	/// implementing this standard
	///
	/// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
	bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	address public _receiver;

	// / _registerInterface(_INTERFACE_ID_ERC2981);

	event RoyaltyRecieverChanged(address oldReceiver, address newReceiver);

	constructor(address receiver_) {
		require(receiver_ != address(0), 'Royalty: Trying to set zero address as royalty receiver');
		_receiver = receiver_;
	}

	/// @notice Called with the sale price to determine how much royalty
	//          is owed and to whom.
	/// @param _salePrice - the sale price of the NFT asset specified by _tokenId
	/// @return receiver - address of who should be sent the royalty payment
	/// @return royaltyAmount - the royalty payment amount for _salePrice
	function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
		royaltyAmount = (_salePrice / 1000) * 75;
		receiver = _receiver;
	}

	function _changeRoyaltyReceiver(address receiver_) internal {
		require(receiver_ != address(0), 'Royalty: Trying to set zero address as royalty receiver');
		require(msg.sender == _receiver, 'Royalty: Only current receiver can change royalty address');
		
		address oldReceiver = _receiver;

		_receiver = receiver_;

		emit RoyaltyRecieverChanged(oldReceiver, receiver_);
	}
}