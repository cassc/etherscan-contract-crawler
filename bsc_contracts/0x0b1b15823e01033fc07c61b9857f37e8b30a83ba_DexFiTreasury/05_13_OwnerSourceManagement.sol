// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/IOwnerSourceManagement.sol";

abstract contract OwnerSourceManagement is IOwnerSourceManagement {
    Ownable public ownerSource;

    function owner() public view returns (address) {
        return ownerSource.owner();
    }

    function updateOwnerSource(address ownerSource_) external onlyOwner returns (bool) {
        _updateOwnerSource(ownerSource_);
        return true;
    }

    function _updateOwnerSource(address ownerSource_) internal {
        require(ownerSource_ != address(0), "OwnerSourceManagement: OwnerSource is zero address");
        ownerSource = Ownable(ownerSource_);
        emit OwnerSourceUpdated(ownerSource_);
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "OwnerSourceManagement: Caller is not owner");
        _;
    }
}