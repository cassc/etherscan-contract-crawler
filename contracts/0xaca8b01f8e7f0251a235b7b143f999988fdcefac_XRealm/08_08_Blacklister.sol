// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklistable is Ownable {
    error AddressIsBlacklisted(address _address);

    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _address);
    event UnBlacklisted(address indexed _address);
    event BlacklisterChanged(address indexed newBlacklister);

    modifier notBlacklisted(address _address) {
        if (blacklisted[_address]) revert AddressIsBlacklisted(_address);
        _;
    }

    function isBlacklisted(address _address) external view returns (bool) {
        return blacklisted[_address];
    }

    function blacklist(address _address) external onlyOwner {
        blacklisted[_address] = true;
        emit Blacklisted(_address);
    }

    function unBlacklist(address _address) external onlyOwner {
        blacklisted[_address] = false;
        emit UnBlacklisted(_address);
    }
}