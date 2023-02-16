// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../interfaces/IWhitelist.sol";

contract Whitelist is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IWhitelist
{
    /**
      @dev GRANT_ROLE: can assign a person can mint or not
     */
    bytes32 public constant override(IWhitelist) GRANT_ROLE =
        keccak256("GRANT_ROLE");

    /**
      @dev ADMIN_ROLE: can assign a person to be a granter
     */
    bytes32 public constant  override(IWhitelist) ADMIN_ROLE = keccak256("ADMIN_ROLE");

    using AddressUpgradeable for address;

    event ContractAdminChanged(address from, address to);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __AccessControl_init();
        _setupRole(ADMIN_ROLE, _msgSender());
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev change contract's admin to a new address
     */
    function changeContractAdmin(
        address _newAdmin
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        // Check if the new Admin address is a contract address
        require(!_newAdmin.isContract(), "New admin must not be a contract");

        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());

        emit ContractAdminChanged(_msgSender(), _newAdmin);
    }

    function addGrantRole(address account) public onlyRole(ADMIN_ROLE) {
        _setupRole(GRANT_ROLE, account);
        _setRoleAdmin(GRANT_ROLE, ADMIN_ROLE);
    }

    function hasRole(
        bytes32 role,
        address account
    )
        public
        view
        override(AccessControlUpgradeable, IWhitelist)
        returns (bool)
    {
        return super.hasRole(role, account);
    }

    function setRole(bytes32 role, address account) public {
        _setupRole(role, account);
    }
}