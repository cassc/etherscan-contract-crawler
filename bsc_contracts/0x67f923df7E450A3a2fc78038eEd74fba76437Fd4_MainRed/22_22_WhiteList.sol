// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Administered.sol";

contract WhiteList is Administered {
    mapping(address => bool) private _whitelist;

    event WhitelistedAddressAdded(address indexed account);
    event WhitelistedAddressRemoved(address indexed account);

    constructor() {}

    modifier onlyWhitelisted() {
        require(
            _whitelist[_msgSender()],
            "Whitelisted: caller is not the whitelisted"
        );
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function addWhitelisted(address account) public onlyAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyAdmin {
        _removeWhitelisted(account);
    }

    function _addWhitelisted(address account) internal {
        _whitelist[account] = true;
        emit WhitelistedAddressAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelist[account] = false;
        emit WhitelistedAddressRemoved(account);
    }
}