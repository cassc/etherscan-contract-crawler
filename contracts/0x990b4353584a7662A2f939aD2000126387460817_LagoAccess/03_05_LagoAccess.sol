// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../interface/ILagoAccessList.sol";
import "../interface/ILagoAccess.sol";

import "openzeppelin-contracts/access/Ownable.sol";

// @dev interface for Chainalsys sactions oracle
// https://go.chainalysis.com/chainalysis-oracle-docs.html
interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

/// @dev Chainalysis sanctions oracle address
// https://go.chainalysis.com/chainalysis-oracle-docs.html
SanctionsList constant SANCTIONS_LIST = SanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);

/// @dev helper functions for allow & deny lists
contract LagoAccess is ILagoAccess, Ownable {
    event AllowListUpdated(address current, address previous);
    event DenyListUpdated(address current, address previous);
    event UseSanctionsList(bool);

    bool public useSanctionsList;

    /// @dev Allow list
    ILagoAccessList public allowList;

    /// @dev Deny list
    ILagoAccessList public denyList;

    constructor(address owner_, ILagoAccessList allowList_, ILagoAccessList denyList_) Ownable() {
        if (owner_ != _msgSender()) {
            Ownable.transferOwnership(owner_);
        }

        _setAllowList(allowList_);
        _setDenyList(denyList_);

        if (block.chainid == 1 || block.chainid == 31337) {
            _setUseSanctionsList(true);
        }
    }

    /// @inheritdoc ILagoAccess
    function isAllowed(address a) external view returns (bool) {
        return _isAllowed(a, LAGO_ACCESS_ANY);
    }

    /// @inheritdoc ILagoAccess
    function isAllowed(address a, address b) external view returns (bool) {
        return _isAllowed(a, b);
    }

    /// @dev check address pair status in both allow & deny lists
    function _isAllowed(address a, address b) internal view returns (bool) {
        // ensure addresses are NOT sanctioned if sanctions list check is enabled
        if (useSanctionsList) {
            if (a != LAGO_ACCESS_ANY && _isSanctioned(a)) {
                return false;
            }
            if (b != LAGO_ACCESS_ANY && _isSanctioned(b)) {
                return false;
            }
        }

        // If allowList exists, fail if not on the list
        if (address(allowList) != address(0)) {
            if (!allowList.isMember(a, b)) {
                return false;
            }
        }

        // If denyList exists, fail if on the list
        if (address(denyList) != address(0)) {
            if (denyList.isMember(a, b)) {
                return false;
            }
        }

        // all checks pass
        return true;
    }

    function _isSanctioned(address a) internal view returns (bool) {
        return SANCTIONS_LIST.isSanctioned(a);
    }

    function _setAllowList(ILagoAccessList allowList_) internal {
        emit AllowListUpdated(address(allowList_), address(allowList));
        allowList = allowList_;
    }

    function _setDenyList(ILagoAccessList denyList_) internal {
        emit DenyListUpdated(address(denyList_), address(denyList));
        denyList = denyList_;
    }

    function _setUseSanctionsList(bool enable_) internal {
        emit UseSanctionsList(enable_);
        useSanctionsList = enable_;
    }

    /// update the allowList
    /// @param allowList_ address of LagoAccessList contract used as allow list
    function setAllowList(ILagoAccessList allowList_) external onlyOwner {
        _setAllowList(allowList_);
    }

    /// update the denyList
    /// @param denyList_ address of LagoAccessList contract used as deny list
    function setDenyList(ILagoAccessList denyList_) external onlyOwner {
        _setDenyList(denyList_);
    }

    /// enable/disable sanctions list check
    /// @param enable_ true to enable, false to disable sanctions list checking
    function setUseSanctionsList(bool enable_) external onlyOwner {
        _setUseSanctionsList(enable_);
    }
}