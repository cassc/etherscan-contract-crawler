// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Payments.sol";
import "./ProxyStorage.sol";

contract PaymentFactory is ProxyStorage, Ownable {
	mapping(address => address[]) public payments;

	function create(address[] memory _payees, uint256[] memory _shares) public returns(address) {
		Payments paymentAddress = new Payments(_payees, _shares);
		payments[msg.sender].push(address(paymentAddress));

		return address(paymentAddress);
	}

	function getPaymentsCount() public view returns(uint count) {
		return payments[msg.sender].length;
	}
}