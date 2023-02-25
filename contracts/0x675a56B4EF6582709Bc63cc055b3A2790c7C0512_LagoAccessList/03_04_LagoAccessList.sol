// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../interface/ILagoAccessList.sol";
import "openzeppelin-contracts/access/Ownable.sol";

/// @dev Generic access list contract
contract LagoAccessList is ILagoAccessList, Ownable {
    event AccessUpdated(address addr1, address addr2, bool status);

    /// @dev members of the access list
    mapping(address => mapping(address => bool)) public member;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    /// @inheritdoc ILagoAccessList
    function set(address addr, bool status) external onlyOwner {
        _set(addr, LAGO_ACCESS_ANY, status);
    }

    /// @inheritdoc ILagoAccessList
    function set(address addr1, address addr2, bool status) external onlyOwner {
        _set(addr1, addr2, status);
    }

    function _set(address addr1, address addr2, bool status) internal {
        emit AccessUpdated(addr1, addr2, status);
        member[addr1][addr2] = status;
    }

    /// @inheritdoc ILagoAccessList
    function isMember(address addr1, address addr2) public view returns (bool) {
        if (member[addr1][LAGO_ACCESS_ANY] || member[LAGO_ACCESS_ANY][addr2]) {
            return true;
        }
        return member[addr1][addr2];
    }
}