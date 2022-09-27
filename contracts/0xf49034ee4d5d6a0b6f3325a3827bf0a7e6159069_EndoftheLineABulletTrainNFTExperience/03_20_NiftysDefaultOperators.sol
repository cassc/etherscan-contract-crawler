// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract NiftysDefaultOperators is Context {
    address private _defaultOperator;

    error DefaultOperatorExists();

    event DefaultOperatorRevoked(address operator, address user);

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    /**
     * @dev Sets `_defaultOperator` to `account`.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the default operator for the system.
     *
     * Using this function in any other way is effectively circumventing the
     * sequrity of the system
     * ====
     */
    function _setupDefaultOperator(address account) internal virtual {
        if (_defaultOperator != address(0)) revert DefaultOperatorExists();
        _defaultOperator = account;
    }

    function _globalRevokeDefaultOperator() internal virtual {
        _defaultOperator = address(0);
    }

    function defaultOperator() public view virtual returns (address) {
        return _defaultOperator;
    }

    function isDefaultOperatorFor(address tokenHolder, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return _defaultOperator == operator && !_revokedDefaultOperators[tokenHolder][operator];
    }

    function revokeDefaultOperator() public virtual {
        _revokedDefaultOperators[_msgSender()][_defaultOperator] = true;
        emit DefaultOperatorRevoked(_defaultOperator, _msgSender());
    }
}