// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

abstract contract PreAuthorisable {

    mapping(address => bool) private authorizedAddresses;

    constructor(address[] memory _preAuthorized) {
        for (uint256 i = 0; i < _preAuthorized.length; i++) {
            _setAuthorizedAddress(_preAuthorized[i], true);
        }
    }

    function _setAuthorizedAddress(address authorizedAddress, bool authorized) internal {
        authorizedAddresses[authorizedAddress] = authorized;
    }

    function _isAuthorizedAddress(address operator) internal view returns (bool) {
        return authorizedAddresses[operator];
    }
}