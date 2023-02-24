// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../../interface/IERC173.sol";
import "../../interface/extensions/IOperator.sol";
import "../../interface/errors/IERC173Errors.sol";
import "../../interface/errors/extensions/IOperatorErrors.sol";

contract Operator is IERC173, IOperator, IERC173Errors, IOperatorErrors {
	address private _owner;
	address private _operator;

	constructor(address owner_) {
		_transferOwnership(owner_);
	}

	modifier ownership() {
		if (owner() != msg.sender) {
			revert NonOwnership(owner(), msg.sender);
		}
		_;
	}

	modifier operatorship() {
		if (owner() == msg.sender || operator() == msg.sender) {
			_;
		} else {
			revert NonOperator(operator(), msg.sender);
		}
	}

	function transferOwnership(
		address _to
	) public virtual override(IERC173) ownership {
		if (_to == address(0)) {
			revert TransferOwnershipToZeroAddress(owner(), _to);
		}
		_transferOwnership(_to);
	}

	function transferOperatorship(
		address _to
	) public virtual override(IOperator) ownership {
		_transferOperatorship(_to);
	}

	function owner() public view virtual override(IERC173) returns (address) {
		return _owner;
	}

	function operator()
		public
		view
		virtual
		override(IOperator)
		returns (address)
	{
		return _operator;
	}

	function _transferOwnership(address _to) internal virtual {
		address _from = _owner;
		_owner = _to;
		delete _operator;
		emit OwnershipTransferred(_from, _to);
	}

	function _transferOperatorship(address _to) internal virtual {
		address _from = _operator;
		_operator = _to;
		emit OperatorshipTransferred(_from, _to);
	}
}