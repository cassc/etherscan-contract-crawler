//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;
import "openzeppelin-contracts/contracts/finance/PaymentSplitter.sol";

contract GhoulsRoyalties is PaymentSplitter {
	constructor(address[] memory payees, uint256[] memory shares_)
		PaymentSplitter(payees, shares_)
	{}
}