// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Owners {
    event OwnerSet(address indexed owner, bool active);

    mapping(address => bool) public owners;

    modifier isOwner() {
        require(owners[msg.sender], "Unauthorized");
        _;
    }

    function _setOwner(address owner, bool active) internal virtual {
        owners[owner] = active;
        emit OwnerSet(owner, active);
    }

    function setOwner(address owner, bool active) external virtual isOwner {
        _setOwner(owner, active);
    }
}