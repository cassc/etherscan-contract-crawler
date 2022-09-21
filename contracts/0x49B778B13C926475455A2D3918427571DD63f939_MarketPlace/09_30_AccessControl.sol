// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract GenericAccessControl is AccessControlUpgradeable {
    mapping(address => bool) internal whitelist;
    address marketcontractAddr;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function __GenericAccessControl_init(address[] memory _whitelist)
        internal
        initializer
    {
        __Context_init_unchained();
        //Add creator to the list of admins
        whitelist[_msgSender()] = true;
        ///Setting white list addresses as true
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    modifier OnlyAdmin() {
        require(whitelist[_msgSender()], "Sender is not an Admin");
        _;
    }

    modifier OnlyAllowedContract(address contractAddr) {
        require(
            msg.sender == contractAddr,
            "Only allowed contract can call this function"
        );
        _;
    }

    function addAddressToWhitelist(address addr) external OnlyAdmin {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    function removeAddressFromWhitelist(address addr) external OnlyAdmin {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
    }
}