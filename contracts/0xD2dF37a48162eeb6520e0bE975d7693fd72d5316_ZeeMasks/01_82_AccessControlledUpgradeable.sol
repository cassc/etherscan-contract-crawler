// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "./IAccessControlled.sol";
import "../Roles.sol";
import "../IACL.sol";

/// @notice Modifier provider for contracts that want to interact with the ACL contract.
abstract contract AccessControlledUpgradeable is IAccessControlled, ContextUpgradeable {
    bytes32 private constant _ACL_SLOT = bytes32(uint256(keccak256("zee-game.acl.slot")) - 1);

    modifier onlyRole(bytes32 role) {
        _getAcl().checkRole(role, _msgSender());
        _;
    }

    /// @dev Modifier to make a function callable by the admin account.
    modifier onlyAdmin() {
        _getAcl().checkRole(Roles.ADMIN, _msgSender());
        _;
    }

    /// @dev Modifier to make a function callable by a supervisor account.
    modifier onlyMaintainer() {
        _getAcl().checkRole(Roles.MAINTAINER, _msgSender());
        _;
    }

    function __AccessControlled_init(address acl) internal onlyInitializing {
        // solhint-disable-previous-line func-name-mixedcase
        // TODO check ACL interface
        StorageSlot.getAddressSlot(_ACL_SLOT).value = acl;
    }

    /// @inheritdoc IAccessControlled
    function getACL() external view returns (address) {
        // solhint-disable-previous-line ordering
        return address(_getAcl());
    }

    /// @dev return the IACL address
    function _getAcl() internal view returns (IACL) {
        return IACL(StorageSlot.getAddressSlot(_ACL_SLOT).value);
    }
}