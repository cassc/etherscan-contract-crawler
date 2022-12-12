// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./IACL.sol";
import "./Roles.sol";

error ACLContractIsZeroAddress();
error ACLAddressIsNotContract();

abstract contract AccessControllable is Initializable, ContextUpgradeable {
    using AddressUpgradeable for address;
    IACL internal _accessControl;
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    modifier onlyAdmin() {
        _accessControl.checkRole(Roles.ADMIN, _msgSender());
        _;
    }

    modifier onlyOperator() {
        _accessControl.checkRole(Roles.OPERATOR, _msgSender());
        _;
    }

    modifier onlyMinter() {
        _accessControl.checkRole(Roles.MINTER, _msgSender());
        _;
    }

    modifier onlyFreeClaimer() {
        _accessControl.checkRole(Roles.FREE_CLAIMER, _msgSender());
        _;
    }

    modifier onlyRole(bytes32 role) {
        _accessControl.checkRole(role, _msgSender());
        _;
    }

    function owner() external view virtual returns (address) {
        return _getOwner();
    }

    function getOwner() external view virtual returns (address) {
        return _getOwner();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __AccessControllable_init(address aclContract) internal onlyInitializing {
        __AccessControllable_init_unchained(aclContract);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __AccessControllable_init_unchained(address aclContract) internal onlyInitializing {
        if (aclContract == address(0)) revert ACLContractIsZeroAddress();
        if (!aclContract.isContract()) revert ACLAddressIsNotContract();
        _accessControl = IACL(aclContract);
    }

    function _acl() internal virtual returns (IACL) {
        return _accessControl;
    }

    function _getOwner() internal view returns (address) {
        if (_accessControl.getRoleMemberCount(Roles.OWNER) == 0) return address(0);

        return _accessControl.getRoleMember(Roles.OWNER, 0);
    }
}