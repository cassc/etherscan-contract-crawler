// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Blaklistable contract manages blacklist addresses
 */
contract Blacklistable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _blacklisted;

    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);

    /**
     * @dev revert if argument account is blacklisted
     * @param account The address to check
     */
    modifier notBlacklisted(address account) {
        require(!isBlacklisted(account), "Blacklistable: account is blacklisted");
        _;
    }

    /**
     * @dev check whether account is blacklisted or not
     * @param account The address to check
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted.contains(account);
    }

    /**
     * @dev get the number of accounts blacklisted
     * @return count the number of accounts in blacklisted address set.
     */
    function blacklistedCount() external view returns (uint256) {
        return _blacklisted.length();
    }

    /**
     * @dev get the blacklisted address at the index from the address set
     * @param index the index of address set
     * @return address the account blacklisted in the array with the given index
     */
    function blacklistedAt(uint256 index) external view returns (address) {
        return _blacklisted.at(index);
    }

    /**
     * @dev adds account to blacklist and emits the event
     * @param account The address to blacklist
     */
    function _addBlacklist(address account) internal {
        require(_blacklisted.add(account), "Blacklistable: account is already in blacklist");
        emit Blacklisted(account);
    }

    /**
     * @dev removes account from blacklist and emits the event
     * @param account The address to remove from the blacklist
     */
    function _removeBlacklist(address account) internal {
        require(_blacklisted.remove(account), "Blacklistable: account is not in blacklist");
        emit UnBlacklisted(account);
    }
}