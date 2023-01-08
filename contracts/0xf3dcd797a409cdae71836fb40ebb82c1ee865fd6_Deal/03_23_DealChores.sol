//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract DealChores is
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function initialize() public virtual initializer {
        __UUPSUpgradeable_init();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        return super._msgSender();
    }

    // slither-disable-next-line dead-code
    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        return super._msgData();
    }
}