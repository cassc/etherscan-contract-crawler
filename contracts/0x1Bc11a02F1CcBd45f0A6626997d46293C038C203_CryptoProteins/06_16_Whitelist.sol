//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Whitelist is Ownable {
    mapping(address => bool) private _whitelist;

    bool private _isListActive = true;

    modifier inWhitelist(address _address) {
        if (isWhitelistActive()) {
            require(
                isOnWhitelist(_address),
                "You are not in the whitelist with this Wallet");
        }
        _;
    }

    function setWhitelistActive(bool _isActive) external onlyOwner {
        _isListActive = _isActive;
    }

    function isWhitelistActive() public view returns (bool) {
        return _isListActive;
    }

    function addToWhitelist(address[] memory _addresses) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
            if (!_whitelist[_addresses[i]]) {
                _whitelist[_addresses[i]] = true;
            }
        }
    }

    function isOnWhitelist(address _address) public view returns (bool) {
        if (!isWhitelistActive()) {
            return true;
        }

        return _whitelist[_address];
    }
}