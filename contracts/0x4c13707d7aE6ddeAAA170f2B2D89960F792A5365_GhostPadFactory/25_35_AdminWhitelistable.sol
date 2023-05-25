// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../GhostAdminWhitelist.sol';
import '../../node_modules/@openzeppelin/contracts/access/Ownable.sol';

abstract contract AdminWhitelistable is Ownable {
    address private _adminWhitelist;
    event UpdateAdminWhitelist(address indexed _address);

    modifier onlyAdminWhitelist() {
        require(isInWhitelist(msg.sender), 'AdminWhitelistable : whitelist not contains msg.sender');
        _;
    }

    /**
     * @param _newAdminWhitelist: new whitelist contract address
     */
    function _updateAdminWhitelist(address _newAdminWhitelist) internal {
        require(_newAdminWhitelist != address(0), 'AdminWhitelistable: whitelist address cannot be zero');
        _adminWhitelist = _newAdminWhitelist;
        emit UpdateAdminWhitelist(_newAdminWhitelist);
    }

    function updateAdminWhitelist(address _newAdminWhitelist) external onlyOwner {
        _updateAdminWhitelist(_newAdminWhitelist);
    }

    /**
     * @param _address: target address
     */

    function isInWhitelist(address _address) public view returns (bool) {
        return GhostAdminWhitelist(_adminWhitelist).whitelists(_address);
    }
}