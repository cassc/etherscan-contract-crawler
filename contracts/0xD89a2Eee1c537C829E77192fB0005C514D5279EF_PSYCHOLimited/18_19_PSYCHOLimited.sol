// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "./IPSYCHOLimited.sol";
import "./PSYCHOSetup.sol";

/// @title See {IPSYCHOLimited}
/// @notice See {IPSYCHOLimited}
contract PSYCHOLimited is IPSYCHOLimited, PSYCHOSetup {
	/// @dev See {IPSYCHOLimited-mint}
	function mint(uint256 _quantity) public payable override(IPSYCHOLimited) {
		if (!_isOwnerOrOperator(msg.sender)) {
			if (msg.value < _fee(_quantity)) {
				revert FundAccount(_fee(_quantity) - msg.value);
			}
			if (_quantity > _stock()) {
				revert ExceedsStockLimit(_quantity - _stock());
			}
			if (_quantity > 20) {
				revert ExceedsMintLimit(_quantity - 20);
			}
			_addStockCount(_quantity);
		} else {
			if (_quantity > _chest()) {
				revert ExceedsChestLimit(_quantity - _chest());
			}
			_addChestCount(_quantity);
		}
		_eoaMint(msg.sender, _quantity);
	}

	/// @dev See {IPSYCHOLimited-metadata}
	function metadata(
		uint256 _avatarId,
		string memory _image,
		string memory _animation
	) public payable override(IPSYCHOLimited) {
		if (!_isApprovedOrOwner(msg.sender, _avatarId)) {
			revert NonApprovedNonOwner(
				isApprovedForAll(ownerOf(_avatarId), msg.sender),
				getApproved(_avatarId),
				ownerOf(_avatarId),
				msg.sender
			);
		}
		if (!_isOwnerOrOperator(msg.sender)) {
			if (msg.value < _fee(1)) {
				revert FundAccount(_fee(1) - msg.value);
			}
		}
		if (abi.encodePacked(_animation).length == 0) {
			_setCustomImage(_avatarId, _image);
		} else {
			_setCustomImage(_avatarId, _image);
			_setCustomAnimation(_avatarId, _animation);
		}
	}

	/// @dev See {IPSYCHOLimited-fee}
	function fee(
		uint256 _multiplier
	) public view override(IPSYCHOLimited) returns (uint256) {
		return _fee(_multiplier);
	}

	/// @dev See {IPSYCHOLimited-stock}
	function stock() public view override(IPSYCHOLimited) returns (uint256) {
		return _stock();
	}

	/// @dev See {IPSYCHOLimited-chest}
	function chest() public view override(IPSYCHOLimited) returns (uint256) {
		return _chest();
	}
}