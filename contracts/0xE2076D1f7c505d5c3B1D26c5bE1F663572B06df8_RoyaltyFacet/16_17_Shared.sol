// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "./LibDiamond.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";

library Shared {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReceived(address from, uint256 amount);
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param _shares The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 _shares) internal {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(_shares > 0, "PaymentSplitter: shares are 0");
        require(
            s.shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        s.payees.push(account);
        s.shares[account] = _shares;
        s.totalShares = s.totalShares + _shares;
        emit PayeeAdded(account, _shares);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (!hasRole(role, account)) {
            s.roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.roles[role].members[account];
    }
}