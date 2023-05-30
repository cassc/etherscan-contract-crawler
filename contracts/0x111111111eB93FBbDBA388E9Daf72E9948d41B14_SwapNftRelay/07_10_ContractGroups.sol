// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "common/ErrorCodes.sol";
import "../Groups.sol";

/**
 * @dev User groups for SwapRelay.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract ContractGroups is ErrorCodes {
    uint8 public constant ADMIN = 1;
    uint8 public constant SWAPPERS = 7;

    using Groups for Groups.GroupMap;

    Groups.GroupMap groups;

    event AddedToGroup(uint8 indexed groupId, address indexed account);
    event RemovedFromGroup(uint8 indexed groupId, address indexed account);


    modifier onlyAdmin() {
        expect(isAdmin(msg.sender), ERROR_UNAUTHORIZED);
        _;
    }
    // ADMIN

    function _addAdmin(address account) internal {
        _add(ADMIN, account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        _remove(ADMIN, account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _contains(ADMIN, account);
    }

    // SWAPPERS

    function addSwapper(address account) public onlyAdmin {
        _addSwapper(account);
    }

    function _addSwapper(address account) internal {
        _add(SWAPPERS, account);
    }

    function removeSwapper(address account) public onlyAdmin {
        _remove(SWAPPERS, account);
    }

    function isSwapper(address account) public view returns (bool) {
        return _contains(SWAPPERS, account);
    }

    modifier onlySwapper() {
        expect(isSwapper(msg.sender), ERROR_UNAUTHORIZED);
        _;
    }

    // Internal functions

    function _add(uint8 groupId, address account) internal {
        groups.add(groupId, account);
        emit AddedToGroup(groupId, account);
    }

    function _remove(uint8 groupId, address account) internal {
        groups.remove(groupId, account);
        emit RemovedFromGroup(groupId, account);
    }

    function _contains(uint8 groupId, address account) internal view returns (bool) {
        return groups.contains(groupId, account);
    }
}