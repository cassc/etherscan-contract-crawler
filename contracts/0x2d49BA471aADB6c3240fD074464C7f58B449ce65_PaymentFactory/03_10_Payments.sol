// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Payments is PaymentSplitter {
	address payable [] public recipients;
	uint256 [] public partnerShares;
	constructor (address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) payable {
		for (uint i = 0; i< _payees.length; i++) {
			recipients.push(payable(_payees[i]));
		}

		for (uint i = 0; i< _shares.length; i++) {
			partnerShares.push(_shares[i]);
		}
	}

	receive() payable external override {
		for (uint i=0; i< recipients.length; i++) {
			release(recipients[i]);
		}
	}
}