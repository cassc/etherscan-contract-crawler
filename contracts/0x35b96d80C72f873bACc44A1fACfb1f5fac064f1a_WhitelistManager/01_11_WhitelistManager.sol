// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {ISanctionsList} from "../interfaces/IWhitelistManager.sol";

contract WhitelistManager is AccessControlEnumerable {

    bytes32 public constant CUSTOMER_ROLE = keccak256("CUSTOMER_ROLE");
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");

    address public sanctionsOracle;

    bytes4 internal constant GNOSIS_MAGICVALUE = 0x19a05a7e;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Sets the new oracle address
     * @param _newOracle is the address of the new keeper
     */
    function setNewSanctionsOracle(address _newOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newOracle != address(0), "!_newOracle");
        sanctionsOracle = _newOracle;
    }

    /**
     * @notice Checks if customer has been whitelisted
     * @param account the address of the account
     * @return value returning if allowed to transact
     */
    function isCustomerWhitelisted(address account) external view returns (bool) {
        return isPermissionedAndNotSanctions(CUSTOMER_ROLE, account);
    }

    /**
     * @notice Checks if LP has been whitelisted
     * @param account the address of the LP
     * @return value returning if allowed to transact
     */
    function isLPWhitelisted(address account) external view returns (bool) {
        return isPermissionedAndNotSanctions(LP_ROLE, account);
    }

    /**
     * @notice Called by Gnosis EasyAuction AllowListVerifier. Should return whether the a specific user has access to an auction
     * @param user is the address order submitter
     * @return value returning the magic value
     */
    function isAllowed(
        address user,
        uint256 /*auctionId*/,
        bytes calldata /*callData*/
    ) external view returns (bytes4) {
        return isPermissionedAndNotSanctions(LP_ROLE, user) ? GNOSIS_MAGICVALUE : bytes4(0);
    }

    /**
     * @notice Checks if an address has a specific role and is not sanctioned
     * @param role the the specific role
     * @param account the address of the account
     * @return value returning if allowed to transact
     */
    function isPermissionedAndNotSanctions(
        bytes32 role,
        address account
    ) public view returns (bool) {
        return isPermissioned(role, account) && !isSanctioned(account);
    }

    /**
     * @notice Checks if an address has a specific role
     * @param role the the specific role
     * @param account the address of the account
     * @return value returning if allowed to transact
     */
    function isPermissioned(bytes32 role, address account) public view returns (bool) {
        require(account != address(0), "!account");
        return getRoleMemberCount(role) > 0
            ? hasRole(role, account)
            : true;
    }

    /**
     * @notice Checks if an address is sanctioned
     * @param account the address of the account
     * @return value returning if allowed to transact
     */
    function isSanctioned(address account) public view returns (bool) {
        require(account != address(0), "!account");
        return sanctionsOracle != address(0)
            ? ISanctionsList(sanctionsOracle).isSanctioned(account)
            : false;
    }
}