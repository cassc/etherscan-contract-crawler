// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Security is Ownable, Pausable {
    
    mapping(address => bool) isBlackListed;

    /**
     * @dev Pauses the contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Adds `account` to the blacklist.
     */
    function lockUser(address account) external onlyOwner {
        isBlackListed[account] = true;        
        emit LockedUser(account);
    }

    /**
     @dev Removes `account` from the blacklist.
     */
    function unlockUser(address account) external onlyOwner {
        isBlackListed[account] = false;
        emit UnlockedUser(account);
    }

    event LockedUser(address indexed account);
    event UnlockedUser(address indexed account);
}