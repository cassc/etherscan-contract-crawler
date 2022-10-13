// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

abstract contract WakumbaOwnedUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private __wakumbas;

    function __WakumbaOwned_init() internal onlyInitializing {
        __WakumbaOwned_init_unchained();
    }

    function __WakumbaOwned_init_unchained() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function addWakumba(address addr) public virtual onlyOwner {
        __wakumbas[addr] = true;
    }

    function removeWakumba(address addr) public virtual onlyOwner {
        __wakumbas[addr] = false;
    }

    function isWakumba(address addr) internal view returns (bool) {
        return __wakumbas[addr];
    }

    modifier onlyWakumbas() {
        require(__wakumbas[_msgSender()], 'Only Wakumba is allowed');
        _;
    }
}