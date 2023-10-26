//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "../interfaces/IAuthorization.sol";

/**
 * @title Authorizable
 * @author Protofire
 * @dev Contract module which provides an authorization mechanism.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAuthorized`, which can be applied to your functions to restrict their use.
 */
abstract contract Authorizable is Context {
    /// @dev Address of Authorization contract.
    IAuthorization public authorization;

    /**
     * @dev Emitted when `authorization` address is set.
     */
    event AuthorizationSet(address indexed newAuthorization);

    /**
     * @dev Throws if called by any account which is not authorized to execute the transaction.
     */
    modifier onlyAuthorized() {
        require(
            authorization.isAuthorized(_msgSender(), address(this), msg.sig, _msgData()),
            "Authorizable: not authorized"
        );
        _;
    }

    /**
     * @dev Sets authorization.
     *
     */
    function _setAuthorization(address authorization_) internal {
        require(authorization_ != address(0), "Authorizable: authorization is the zero address");
        authorization = IAuthorization(authorization_);
        emit AuthorizationSet(authorization_);
    }
}