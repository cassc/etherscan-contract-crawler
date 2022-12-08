// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../utils/AdminableUpgradeable.sol";

contract WhitelistUpgradeable is AdminableUpgradeable {

    mapping(address => bool) public whitelist;

    bool public hasWhitelisting;

    event AddedToWhitelist(address account);
    event RemovedFromWhitelist(address account);

    modifier onlyWhitelisted() {
        if(hasWhitelisting){
            require(isWhitelisted(msg.sender));
        }
        _;
    }

    function __Whitelist_init (bool _hasWhitelisting) public initializer {
        __Adminable_init();
        hasWhitelisting = _hasWhitelisting;
    }

    function add(address[] memory _addresses) public onlyOwnerOrAdmin {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;

            emit AddedToWhitelist(_addresses[i]);
        }
    }

    function remove(address[] memory _addresses) public onlyOwnerOrAdmin {
        for (uint i = 0; i < _addresses.length; i++) {
            address uAddress = _addresses[i];
            if(whitelist[uAddress]){
                whitelist[uAddress] = false;
                emit RemovedFromWhitelist(uAddress);
            }
        }
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}