// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Ownable2Step.sol";

/**
* @notice newOperator is the zero address
*/
error Access__ZeroNewOperator();

/**
* @notice newOperator is the same as the old one
*/
error Access__SameOperator(address _operator);

/**
* @notice caller is not the operator
*/
error Access__CallerNeitherOperatorNorOwner(address _caller, address _operator, address _owner);

/**
 * @dev Ownable with an additional role of operator
 */
abstract contract OwnableWithOperator is Ownable2Step {
    address private s_operator;

    /**
     * @dev Emits when the operator has been changed
     * @param _previousOperator address of the previous operator
     * @param _newOperator address of the new operator
     */
    event OperatorChanged(
        address indexed _previousOperator,
        address indexed _newOperator
    );

    /**
     * @dev Throws if called by any account other than the operator or the owner.
     */
    modifier onlyOperatorOrOwner() {
        address currentOwner = owner();
        address currentOperator = s_operator;

        if (currentOperator != _msgSender() && currentOwner != _msgSender()) {
            revert Access__CallerNeitherOperatorNorOwner(_msgSender(), currentOperator, currentOwner);
        }

        _;
    }

    /**
     * @dev Returns the current operator.
     */
    function operator() public view virtual returns (address) {
        return s_operator;
    }

    /**
     * @dev Transfers operator to a new account (`newOperator`).
     * Can only be called by the current owner.
     */
    function changeOperator(address _newOperator) external virtual onlyOwner {
        if (_newOperator == address(0)) {
            revert Access__ZeroNewOperator();
        }
        if (_newOperator == s_operator) {
            revert Access__SameOperator(_newOperator);
        }

        _changeOperator(_newOperator);
    }

    /**
     * @dev Transfers operator to a new account (`newOperator`).
     * Internal function without access restriction.
     */
    function _changeOperator(address _newOperator) internal virtual {
        address oldOperator = s_operator;
        s_operator = _newOperator;
        emit OperatorChanged(oldOperator, _newOperator);
    }

    /**
     * @dev Dismisses the old operator without setting a new one.
     * Can only be called by the current owner.
     */
    function dismissOperator() external virtual onlyOwner {
        _changeOperator(address(0));
    }
}