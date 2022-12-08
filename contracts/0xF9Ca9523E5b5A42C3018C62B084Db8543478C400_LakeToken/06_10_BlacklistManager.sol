// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/utils/Context.sol';
import './Ownable.sol';
import './VestingManager.sol';
import 'hardhat/console.sol';

error BlacklistManager_Error(string msg);

abstract contract BlacklistManager is Ownable2Step, VestingManager {
    address private _blacklistManager;
    mapping(address => bool) internal blacklist;

    event BlacklistManagerChanged(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial blacklist manager.
     */
    constructor() {
        _setBlacklistManager(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the blacklist manager.
     */
    modifier onlyBlacklistManager() {
        if (_msgSender() != _blacklistManager) {
            revert BlacklistManager_Error('Caller is not the blacklist manager!');
        }
        _;
    }

    /**
     * @dev Returns the address of the current blacklist manager.
     */
    function blacklistManager() public view returns (address) {
        return _blacklistManager;
    }

    /**
     * @dev Sets blacklist manager.
     */
    function setBlacklistManager(address newManager) public virtual onlyOwner {
        if (newManager == address(0)) {
            revert BlacklistManager_Error('New manager is a zero address!');
        }
        _setBlacklistManager(newManager);
    }

    /**
     * @dev Sets blacklist manager.
     * Internal function without access restriction.
     */
    function _setBlacklistManager(address newManager) internal virtual {
        address oldManager = _blacklistManager;
        _blacklistManager = newManager;
        emit BlacklistManagerChanged(oldManager, newManager);
    }

    /**
     * @dev Checks is account on blacklist
     * @param _account address
     * @return bool true if on blacklist
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklist[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account Address of blacklisted wallet
     * @return bool true if succeed
     */
    function addToBlacklist(address _account) external onlyBlacklistManager returns (bool) {
        if (_account == vesting) {
            revert BlacklistManager_Error('Cannot add Vesting contract address to the blacklist!');
        }
        blacklist[_account] = true;
        emit AddedToBlacklist(_account);
        return true;
    }

    /**
     * @dev Removes account from blacklist
     * @param _account array of addresses
     * @return bool true if succeed
     */
    function removeFromBlacklist(address _account) external onlyBlacklistManager returns (bool) {
        blacklist[_account] = false;
        emit RemovedFromBlacklist(_account);
        return true;
    }

    /**
     * @dev Event is triggered when account is added to the blacklist
     * @param _account address
     */
    event AddedToBlacklist(address _account);

    /**
     * @dev Event is triggered when account is removed from the blacklist
     * @param _account address
     */

    event RemovedFromBlacklist(address _account);
}