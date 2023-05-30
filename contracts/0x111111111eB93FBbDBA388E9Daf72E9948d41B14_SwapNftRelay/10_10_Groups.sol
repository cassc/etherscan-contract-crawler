// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity >=0.8.9;

error Unauthorized(uint8 group);

/**
 * @dev Unified system for arbitrary user groups.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
library Groups {
    struct MemberMap {
        mapping(address => bool) members;
    }

    struct GroupMap {
        mapping(uint8 => MemberMap) groups;
    }

    /**
     * @dev Add an account to a group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function add(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(!groupContains(group, account));

        group.members[account] = true;
    }

    /**
     * @dev Remove an account from a group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function remove(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal {
        MemberMap storage group = map.groups[groupId];
        require(account != address(0));
        require(groupContains(group, account));

        group.members[account] = false;
    }

    /**
     * @dev Returns true if the account is in the group
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     * @return bool
     */
    function contains(
        GroupMap storage map,
        uint8 groupId,
        address account
    ) internal view returns (bool) {
        MemberMap storage group = map.groups[groupId];
        return groupContains(group, account);
    }

    function groupContains(MemberMap storage group, address account) internal view returns (bool) {
        require(account != address(0));
        return group.members[account];
    }
}