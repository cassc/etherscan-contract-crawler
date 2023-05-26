// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Interface to add allowed operator in addition to owner
 */
abstract contract IWhitelist {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private whitelist;

    event WhitelistAdded(address);
    event WhitelistRemoved(address);

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist.contains(_address);
    }

    function addWhitelist(address _address) external virtual;

    function removeWhitelist(address _address) external virtual;

    function _addWhitelist(address _address) internal {
        require(_address != address(0), "Address should not be empty");
        require(!whitelist.contains(_address), "Already added");
        whitelist.add(_address);
        emit WhitelistAdded(_address);

    }

    function _removeWhitelist(address _address) internal {
        require(whitelist.contains(_address), "Not exist");
        whitelist.remove(_address);
        emit WhitelistRemoved(_address);
    }

    function getWhitelist() external view returns (address[] memory) {
        return whitelist.values();
    }
}