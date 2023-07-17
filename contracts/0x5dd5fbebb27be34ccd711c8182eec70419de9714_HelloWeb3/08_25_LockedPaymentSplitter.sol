// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SlimPaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LockedPaymentSplitter
 * @author @NiftyMike, NFT Culture
 * @dev A wrapper around SlimPaymentSplitter which adds on security elements.
 *
 * Based on OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
 */
abstract contract LockedPaymentSplitter is SlimPaymentSplitter, Ownable {
	/**
	 * @dev Overrides release() method, so that it can only be called by owner.
	 * @notice Owner: Release funds to a specific address.
	 *
	 * @param account Payable address that will receive funds.
	 */
	function release(address payable account) public override onlyOwner {
		super.release(account);
	}

	/**
	 * @dev Triggers a transfer to caller's address of the amount of Ether they are owed, according to their percentage of the
	 * total shares and their previous withdrawals.
	 * @notice Sender: request payment.
	 */
	function releaseToSelf() public {
		super.release(payable(msg.sender));
	}
}