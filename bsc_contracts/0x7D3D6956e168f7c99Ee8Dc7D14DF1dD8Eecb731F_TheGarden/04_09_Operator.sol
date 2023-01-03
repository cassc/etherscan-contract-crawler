// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// Additional access control mechanism on top of {Ownable}.
/// @dev Introduces a new - Operator role, in addition to already existing Owner role.
abstract contract Operator is Context, Ownable {
    /// Address of the Operator
    address private _operator;

    /* EVENTS */
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    /// Default constructor.
    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    /// Returns the current Operator address.
    function operator() public view returns (address) {
        return _operator;
    }

    /// Access control modifier, which only allows Operator to call the annotated function.
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    /// Access control modifier, which only allows Operator or Owner to call the annotated function.
    modifier onlyOwnerOrOperator() {
        require((owner() == msg.sender) || (_operator == msg.sender), "operator: caller is not the owner or the operator");
        _;
    }

    /// Checks if caller is an Operator.
    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    /// Checks if called is an Owner or an Operator.
    function isOwnerOrOperator() public view returns (bool) {
        return (_msgSender() == _operator) || (_msgSender() == owner());
    }

    /// Transfers Operator role to a new address.
    /// @param newOperator_ Address to which the Operator role should be transferred.
    function transferOperator(address newOperator_) public onlyOwnerOrOperator {
        _transferOperator(newOperator_);
    }

    /// Transfers Operator role to a new address.
    /// @param newOperator_ Address to which the Operator role should be transferred.
    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}