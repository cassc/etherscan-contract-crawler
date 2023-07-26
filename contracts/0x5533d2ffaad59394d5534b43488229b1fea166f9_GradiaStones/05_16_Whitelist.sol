// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelist;

    modifier onlyWhitelisted() {
        require(owner() == msg.sender || _whitelist.contains(msg.sender), "You're not permitted to perform this action.");
        _;
    }   

    function getWhitelisted() external view returns (address[] memory) {
        address[] memory whitelisted = new address[](_whitelist.length());
        for (uint i = 0; i < _whitelist.length(); i++) {
            whitelisted[i] = _whitelist.at(i);
        }
        return whitelisted;
    }

    function addWhitelist(address [] memory users) external {
        require(isWhitelisted(_msgSender()) || owner() == _msgSender(), "Permission Denied");
        for (uint256 i = 0; i < users.length; i++) {
            require(!_whitelist.contains(users[i]), "Address already in whitelist");
            _whitelist.add(users[i]);
        }
    }

    function removeWhitelist(address [] memory users) external {
        require(isWhitelisted(_msgSender()) || owner() == _msgSender(), "Permission Denied");
        for (uint256 i = 0; i < users.length; i++) {
            require(_whitelist.contains(users[i]), "Address already in whitelist");
            _whitelist.remove(users[i]);
        }
    }

    function isWhitelisted(address user) public view returns (bool) {
        return (owner() == user || _whitelist.contains(user));
    }

}