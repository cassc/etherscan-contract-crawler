// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract CrowdsaleAccessControl is Ownable, Pausable {
    /**
     * @dev Pauses the crowdsale contract.
     * Only Owner can pause the contract.
     * Mint cannot be performed while the contract is paused
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unPauses the crowdsale contract.
     * Only Owner can unpause the contract.
     * unPaused by default.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}