// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IDEXAccessControl.sol";

contract DEXAccessControl is IDEXAccessControl, Ownable {
    /**
     * @inheritdoc IDEXAccessControl
     */
    bool public locked = false;

    /**
     * @inheritdoc IDEXAccessControl
     */
    bool public deprecated = false;

    /**
     * @dev Unlocked DEX function modifier.
     */
    modifier unlocked() {
        require(!locked, "DEX locked");
        _;
    }

    /**
     * @dev Supported (not deprecated) function modifier.
     */
    modifier supported() {
        require(!deprecated, "DEX deprecated");
        _;
    }

    /**
     * @dev Not owner function modifier.
     */
    modifier notOwner() {
        require(owner() != _msgSender(), "Owner prohibited");
        _;
    }

    /**
     * Initializes access control.
     * @param owner_ Address of the administrator account (multisig).
     */
    constructor(address owner_) {
        transferOwnership(owner_);
    }

    /**
     * @inheritdoc IDEXAccessControl
     * @dev This function is only accessible by the administrator account.
     */
    function lock(bool lock_) external override onlyOwner {
        require(lock_ != locked, "State unchanged");
        locked = lock_;
        emit Locked(locked);
    }

    /**
     * @inheritdoc IDEXAccessControl
     * @dev This function is only accessible by the administrator account.
     */
    function deprecate(bool deprecate_) external override onlyOwner {
        require(deprecate_ != deprecated, "State unchanged");
        deprecated = deprecate_;
        emit Deprecated(deprecated);
    }

    /**
     * @dev This function is disabled.
     */
    function renounceOwnership() public override onlyOwner {
        revert("Disabled");
    }
}