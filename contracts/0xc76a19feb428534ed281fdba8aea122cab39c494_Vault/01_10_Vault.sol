// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Vault is
    AccessControl
{
    address public owner;
    address public operator;

    IERC20 public immutable vaultToken;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OperatorChanged(
        address indexed previousOperator,
        address indexed newOperator
    );

    event Withdrawn(address indexed _to, uint256 _amount);

    constructor(IERC20 token) {
        _grantRole("ADMIN_ROLE", msg.sender);
        _grantRole("OPERATOR_ROLE", msg.sender);
        vaultToken = token;
        owner = msg.sender;
        operator = msg.sender;
    }

    function transferOwnership(
        address newOwner
    ) external onlyRole("ADMIN_ROLE") returns (bool) {
        require(newOwner != address(0), "new owner is the zero address");
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _grantRole("ADMIN_ROLE", newOwner);
        return true;
    }

    function changeOperator(
        address newOperator
    ) external onlyRole("ADMIN_ROLE") returns (bool) {
        require(newOperator != address(0), "new Operator is the zero address");
        _revokeRole("OPERATOR_ROLE", operator);
        emit OperatorChanged(operator, newOperator);
        operator = newOperator;
        _grantRole("OPERATOR_ROLE", newOperator);
        return true;
    }

    /**
     * @dev allows authorized caller to transfer `amountInWei` wei from vault to address `to`
     *
     */
    function transferFromVault(
        address to,
        uint256 amountInWei
    ) external onlyRole("OPERATOR_ROLE") returns (bool) {
        bool success = vaultToken.transfer(to, amountInWei);
        emit Withdrawn(to, amountInWei);
        return success;
    }
}