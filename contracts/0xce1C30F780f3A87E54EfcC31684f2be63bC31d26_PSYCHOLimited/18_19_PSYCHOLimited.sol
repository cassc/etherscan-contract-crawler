// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "./IPSYCHOLimited.sol";
import "./PSYCHOSetup.sol";

/// @title See {IPSYCHOLimited}
/// @notice See {IPSYCHOLimited}
contract PSYCHOLimited is IPSYCHOLimited, PSYCHOSetup {
	uint256 private _count = 0;

	/// @dev See {IPSYCHOLimited-metadata}
	function metadata(
		uint256 _avatarId,
		string memory _json
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
		_setCustomExtension(_avatarId, _json);
	}

	/// @dev See {IPSYCHOLimited-fee}
	function fee(
		uint256 _multiplier
	) public view override(IPSYCHOLimited) returns (uint256) {
		return _fee(_multiplier);
	}

	/// @dev See {IPSYCHOLimited-stock}
	function stock() public view override(IPSYCHOLimited) returns (uint256) {
		if (_generative()) {
			return 1001 - _count;
		} else {
			return 0;
		}
	}

	/// @dev See {IPSYCHOLimited-mint}
	function mint(uint256 _quantity) public payable override(IPSYCHOLimited) {
		if (!_isOwnerOrOperator(msg.sender)) {
			if (stock() == 0) {
				revert StockRemaining(stock());
			}
			if (msg.value < _fee(_quantity)) {
				revert FundAccount(_fee(_quantity) - msg.value);
			}
			if (_count + _quantity > 1001) {
				revert ExceedsGenerationLimit((_count + _quantity) - 1001);
			}
			if (_quantity > 20) {
				revert ExceedsGenerationLimit(_quantity - 20);
			}
			unchecked {
				_count += _quantity;
			}
		} else {
			if (_countMaster() + _quantity > 99) {
				revert ExceedsGenerationLimit(
					(_countMaster() + _quantity) - 99
				);
			}
			_addCountMaster();
		}
		_eoaMint(msg.sender, _quantity);
	}

	/// @dev See {IPSYCHOLimited-burn}
	function burn(uint256 _avatarId) public override(IPSYCHOLimited) {
		if (tx.origin != msg.sender) {
			revert TxOriginNonSender(tx.origin, msg.sender);
		}
		_burn(msg.sender, _avatarId);
		if (!_isOwnerOrOperator(msg.sender)) {
			unchecked {
				_count -= 1;
			}
		} else {
			_subtractCountMaster();
		}
	}
}