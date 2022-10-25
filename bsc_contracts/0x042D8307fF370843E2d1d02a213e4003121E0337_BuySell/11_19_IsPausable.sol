// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract IsPausable is Initializable, OwnableUpgradeable {
    //============== INITIALIZE ==============
    function __IsPausable_init() internal onlyInitializing {
        __IsPausable_init_unchained();
    }

    function __IsPausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    //============== EVENTS ==============

    event Paused(address account);
    event Unpaused(address account);

    //============== VARIABLES ==============
    bool private _paused;

    //============== CONSTRUCTOR ==============

    constructor() {
        _disableInitializers();
    }

    //============== MODIFIERS ==============

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    //============== VIEW FUNCTIONS ==============

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    //============== INTERNAL FUNCTIONS ==============

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    //============== EXTERNAL FUNCTIONS ==============

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    uint256[50] private __gap;
}