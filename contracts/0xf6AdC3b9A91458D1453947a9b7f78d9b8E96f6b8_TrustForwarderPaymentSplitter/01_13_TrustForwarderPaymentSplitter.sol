// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./TrustForwarderAccessControl.sol";

 contract TrustForwarderPaymentSplitter is PaymentSplitter, TrustForwarderAccessControl {

    constructor(address[] memory _payees, uint256[] memory _shares) payable PaymentSplitter(_payees, _shares) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public override onlyRole(TRUSTEE_ROLE) {
       super.release(account); 
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public override onlyRole(TRUSTEE_ROLE) {
        super.release(token, account);
    }

}