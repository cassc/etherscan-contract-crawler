//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * Abstract base contract for collections.
 */
abstract contract Collection is AccessControl, ReentrancyGuard {

    /*********/
    /* Types */
    /*********/

    /**
     * Constant used for representing the minter role.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /***************/
    /* Constructor */
    /***************/

    /**
     * Creates a new instance of this contract.
     *
     * @param creator The creator address that will be given the default admin
     *     role.
     * @param marketplace The marketplace address that will be given minter
     *     role.
     */
    constructor(
        address creator,
        address marketplace
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, creator);
        _grantRole(MINTER_ROLE, marketplace);
    }
}