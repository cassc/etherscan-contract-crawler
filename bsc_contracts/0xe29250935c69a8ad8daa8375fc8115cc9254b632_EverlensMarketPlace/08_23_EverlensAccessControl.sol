// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract EverlensAccessControl is Initializable, ContextUpgradeable {
    mapping(address => bool) internal whitelist;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function __EverlensAccessControl_init(address[] memory _whitelist)
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

    function addAddressToWhitelist(address addr) external OnlyAdmin {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    function removeAddressFromWhitelist(address addr) external OnlyAdmin {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
    }
}