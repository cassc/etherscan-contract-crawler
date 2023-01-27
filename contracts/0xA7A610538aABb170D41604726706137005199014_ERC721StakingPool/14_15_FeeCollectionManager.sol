// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FeeCollectionManager is Ownable
{
	address payable public feeRecipient;

	mapping(bytes4 => uint256) public fixedValueFee;

	constructor()
	{
	}

	function setFeeRecipient(address payable _feeRecipient) external onlyOwner
	{
		feeRecipient = _feeRecipient;
		emit UpdateFeeRecipient(_feeRecipient);
	}

	function setFixedValueFee(bytes4[] calldata _selectors, uint256 _fixedValueFee) external onlyOwner
	{
		for (uint256 _i = 0; _i < _selectors.length; _i++) {
			bytes4 _selector = _selectors[_i];
			fixedValueFee[_selector] = _fixedValueFee;
			emit UpdateFixedValueFee(_selector, _fixedValueFee);
		}
	}

	event UpdateFeeRecipient(address _feeRecipient);
	event UpdateFixedValueFee(bytes4 indexed _selector, uint256 _fixedValueFee);
}