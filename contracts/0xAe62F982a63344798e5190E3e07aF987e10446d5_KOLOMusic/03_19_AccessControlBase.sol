// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AccessControlBase is AccessControlEnumerable, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BUSINESS_ROLE = keccak256("BUSINESS_ROLE");
    bytes32 public constant FUNDS_ROLE = keccak256("FUNDS_ROLE");

    modifier onlyFunds() {
        _checkRole(FUNDS_ROLE, msg.sender);
        _;
    }

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _;
    }

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, msg.sender);
        _;
    }

    modifier onlyBusiness() {
        _checkRole(BUSINESS_ROLE, msg.sender);
        _;
    }

    constructor() {
        _init_admin_role();
    }

    // init creator as admin role
    function _init_admin_role() internal virtual {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        _setupRole(BUSINESS_ROLE, msg.sender);
        _setupRole(FUNDS_ROLE, msg.sender);
    }

    function pause() public virtual onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        _pause();
    }

    function unpause() public virtual onlyRole(getRoleAdmin(DEFAULT_ADMIN_ROLE)) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}