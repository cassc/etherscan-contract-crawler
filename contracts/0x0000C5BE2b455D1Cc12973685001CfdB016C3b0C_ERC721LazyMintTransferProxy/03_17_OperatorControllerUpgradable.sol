// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OperatorControllerUpgradeable is OwnableUpgradeable {
    mapping(address => bool) _operators;

    event OperatorSet(address indexed account, bool indexed status);

    modifier onlyOperator() {
        address sender = _msgSender();
        (bool isValid, string memory errorMessage) = _validateOperator(sender);
        require(isValid, errorMessage);
        _;
    }

    modifier onlyOperatorOrOwner() {
        address sender = _msgSender();
        (bool isValid, string memory errorMessage) = _validateOperatorOrOwner(
            sender
        );
        require(isValid, errorMessage);
        _;
    }

    function __OperatorController_init_unchained(address account) internal {
        _setOperator(account, true);
    }

    function addOperator(address account) external onlyOwner {
        _setOperator(account, true);
    }

    function removeOperator(address account) external onlyOwner {
        _setOperator(account, false);
    }

    function isOperator(address account) external view returns (bool) {
        return _isOperator(account);
    }

    function _setOperator(address account, bool status) internal {
        _operators[account] = status;
        emit OperatorSet(account, status);
    }

    function _isOperator(address account) internal view returns (bool) {
        return _operators[account];
    }

    function _isOperatorOrOwner(address account) internal view returns (bool) {
        return owner() == account || _isOperator(account);
    }

    function _validateOperator(address account)
        internal
        view
        returns (bool, string memory)
    {
        if (!_isOperator(account)) {
            return (
                false,
                "OperatorControllerUpgradeable: operator verification failed"
            );
        }
        return (true, "");
    }

    function _validateOperatorOrOwner(address account)
        internal
        view
        returns (bool, string memory)
    {
        if (!_isOperatorOrOwner(account)) {
            return (
                false,
                "OperatorControllerUpgradeable: operator or owner verification failed"
            );
        }
        return (true, "");
    }

    uint256[50] private __gap;
}