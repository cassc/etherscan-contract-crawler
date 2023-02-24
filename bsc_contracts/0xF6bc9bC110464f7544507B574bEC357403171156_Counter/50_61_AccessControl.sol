// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./Ownable.sol";

abstract contract AccessControl is Ownable {
    // role => address => permit
    mapping(bytes32 => mapping(address => bool)) private _permits;

    event RoleGranted(bytes32 indexed role, address indexed grantee);

    event RoleRevoked(bytes32 indexed role, address indexed revokee);

    error NoPermit(bytes32 role);

    constructor(address owner_) Ownable(owner_) {}

    modifier onlyRole(bytes32 role) {
        if (!_permits[role][msg.sender]) revert NoPermit(role);
        _;
    }

    function grantRole(
        bytes32 role_,
        address grantee_
    ) external virtual onlyOwner {
        _grantRole(role_, grantee_);
    }

    function revokeRole(
        bytes32 role_,
        address revokee_
    ) external virtual onlyOwner {
        _revokeRole(role_, revokee_);
    }

    function _grantRole(bytes32 role_, address grantee_) internal {
        _permits[role_][grantee_] = true;
        emit RoleGranted(role_, grantee_);
    }

    function _revokeRole(bytes32 role_, address revokee_) internal {
        _permits[role_][revokee_] = false;
        emit RoleRevoked(role_, revokee_);
    }

    function hasRole(
        bytes32 role_,
        address address_
    ) external view returns (bool) {
        return _hasRole(role_, address_);
    }

    function _hasRole(
        bytes32 role_,
        address address_
    ) internal view returns (bool) {
        return _permits[role_][address_];
    }
}