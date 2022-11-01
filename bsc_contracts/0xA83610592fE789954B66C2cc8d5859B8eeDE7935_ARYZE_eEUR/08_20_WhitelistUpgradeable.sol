// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev WhitelistUpgradeable is the contract that allows regulate list of addresses
 * that can be recipient for minting in main contract.
 */
contract WhitelistUpgradeable is Initializable {
    /**
     * @dev Whitelist is list of users that are able be mint recipient
     */
    mapping(address => bool) internal _whitelist;

    event Whitelisted(address acoount);
    event Unwhitelisted(address account);

    /**
     * @dev View does account is in whitelist
     */
    function isWhitelisted(address account) external view returns (bool) {
        return _whitelist[account];
    }

    /**
     * @dev Add to whitelist
     */
    function _addToWhitelist(address account) internal virtual {
        _whitelist[account] = true;
        emit Whitelisted(account);
    }

    /**
     * @dev Remove to whitelist
     */
    function _removeFromWhitelist(address account) internal virtual {
        _whitelist[account] = false;
        emit Unwhitelisted(account);
    }
}