// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SharedOwnable is Ownable {
    address private _creator;
    mapping(address => bool) private _sharedOwners;

    event SharedOwnershipAdded(address indexed sharedOwner);
    event SharedOwnershipRemoved(address indexed sharedOwner);

    constructor() Ownable() {
        _creator = msg.sender;
        _setSharedOwner(msg.sender, true);
    }

    modifier onlyCreator() {
        require(_creator == msg.sender, "SharedOwnable: caller is not the creator");
        _;
    }

    modifier onlySharedOwners() {
        require(owner() == msg.sender || _sharedOwners[msg.sender], "SharedOwnable: caller is not a shared owner");
        _;
    }

    function getCreator() external view returns (address) {
        return _creator;
    }

    function isSharedOwner(address account) external view returns (bool) {
        return _sharedOwners[account];
    }

    function setSharedOwner(address account, bool sharedOwner) external onlyCreator {
        _setSharedOwner(account, sharedOwner);
    }

    function _setSharedOwner(address account, bool sharedOwner) private {
        _sharedOwners[account] = sharedOwner;
        if (sharedOwner)
            emit SharedOwnershipAdded(account);
        else
            emit SharedOwnershipRemoved(account);
    }
}