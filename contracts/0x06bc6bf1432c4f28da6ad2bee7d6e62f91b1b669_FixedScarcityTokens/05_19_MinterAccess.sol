// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "openzeppelin-contracts-v4.6.0/contracts/access/Ownable.sol";
import "openzeppelin-contracts-v4.6.0/contracts/access/AccessControl.sol";
import "openzeppelin-contracts-v4.6.0/contracts/access/AccessControlEnumerable.sol";

contract MinterAccess is Ownable, AccessControl, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Sender is not a minter");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function addMinter(address account) external {
        grantRole(MINTER_ROLE, account);
    }

    function renounceMinter(address account) external {
        renounceRole(MINTER_ROLE, account);
    }

    function revokeMinter(address account) external {
        revokeRole(MINTER_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override(AccessControl, AccessControlEnumerable)
    {
        super._grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        override(AccessControl, AccessControlEnumerable)
    {
        super._revokeRole(role, account);
    }
}