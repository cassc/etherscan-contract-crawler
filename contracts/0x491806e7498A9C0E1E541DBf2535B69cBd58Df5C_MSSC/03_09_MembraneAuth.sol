//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice A generic contract which provides custom auth logic to Membrane operations.
/// @author Membrane Labs
abstract contract MembraneAuth {
    mapping(address => bool) private _isOperator;

    constructor() {
        _isOperator[msg.sender] = true;
    }

    modifier requiresAuth() virtual {
        if (!_isOperator[msg.sender]) revert Unauthorized();

        _;
    }

    /**
     * @notice  grant or revoke an account access to auth ops
     * @dev     expected to be called by other operator
     *
     * @param   account_ account to update authorization
     * @param   isAuthorized_ to grant or revoke access
     */
    function setAccountAccess(
        address account_,
        bool isAuthorized_
    ) external requiresAuth {
        if (msg.sender == account_) {
            revert EditOwnAuthorization();
        }
        _isOperator[account_] = isAuthorized_;
    }

    /**
     * @notice  Returns wheter account is a Membrane operator.
     * @dev     expected to be call by account owner
     *          usually user should only give access to helper contracts
     * @param   account_ account to check
     */

    function isAllowedOperator(address account_) external view returns (bool) {
        return _isOperator[account_];
    }

    error Unauthorized();

    error EditOwnAuthorization();
}