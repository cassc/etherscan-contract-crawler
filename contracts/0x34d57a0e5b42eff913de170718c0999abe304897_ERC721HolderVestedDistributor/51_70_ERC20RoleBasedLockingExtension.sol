// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ERC20RoleBasedLockingExtensionInterface {
    function lockForAll() external;

    function unlockForAll() external;

    function canTransfer(address) external view returns (bool);
}

/**
 * @dev Extension to allow locking transfers and only allow certain addresses do to transfers.
 */
abstract contract ERC20RoleBasedLockingExtension is
    ERC165Storage,
    AccessControl,
    ERC20,
    ERC20RoleBasedLockingExtensionInterface
{
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor() {
        _registerInterface(
            type(ERC20RoleBasedLockingExtensionInterface).interfaceId
        );

        _grantRole(TRANSFER_ROLE, msg.sender);
    }

    // ADMIN

    function lockForAll() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NOT_ADMIN");

        _revokeRole(TRANSFER_ROLE, address(0));
    }

    function unlockForAll() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NOT_ADMIN");

        _grantRole(TRANSFER_ROLE, address(0));
    }

    // PUBLIC

    function canTransfer(address operator)
        external
        view
        override
        returns (bool)
    {
        return hasRole(TRANSFER_ROLE, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Storage, AccessControl)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(
            hasRole(TRANSFER_ROLE, address(0)) ||
                hasRole(TRANSFER_ROLE, _msgSender()),
            "TRANSFER_LOCKED"
        );

        super._beforeTokenTransfer(from, to, amount);
    }
}