// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "./LibDiamond.sol";
import {AppStorage, LibAppStorage, Edition} from "./LibAppStorage.sol";

library Shared {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReceived(address from, uint256 amount);
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event EditionCreate(
        uint256 editionIndex,
        string name,
        uint256 price,
        uint256 maxSupply
    );

    error PaymentSplitterAccountAddressZero();
    error PaymentSplitterSharesZero();
    error PaymentSplitterAccountHasShares();
    error EditionsDisabled();
    error NameRequired();

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param _shares The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 _shares) internal {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (account == address(0)) {
            revert PaymentSplitterAccountAddressZero();
        }

        if (_shares == 0) {
            revert PaymentSplitterSharesZero();
        }

        if (s.shares[account] > 0) {
            revert PaymentSplitterAccountHasShares();
        }

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

    function createEdition(
        string memory _name,
        uint256 _maxSupply,
        uint256 _price
    ) internal {
        LibDiamond.enforceIsContractOwner();
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.editionsEnabled) revert EditionsDisabled();
        if (bytes(_name).length == 0) revert NameRequired();

        uint256 index = s.editionsByIndex.length;

        Edition memory _edition = Edition({
            name: _name,
            maxSupply: _maxSupply,
            price: _price,
            totalSupply: 0
        });

        s.editionsByIndex.push(_edition);
        s.maxSupply = s.maxSupply + _maxSupply;

        emit EditionCreate(index, _name, _price, _maxSupply);
    }
}