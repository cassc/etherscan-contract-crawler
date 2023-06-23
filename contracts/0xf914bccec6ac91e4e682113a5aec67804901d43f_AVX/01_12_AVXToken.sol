// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AVX is ERC20, ERC20Burnable, AccessControl {
    address public owner;
    address public operator;
    uint256 private immutable _maxSupply = 522504675 * 1e18;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OperatorChanged(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() ERC20("AVX", "AVX") {
        _grantRole("ADMIN_ROLE", msg.sender);
        _grantRole("OPERATOR_ROLE", msg.sender);
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

    function mint(
        address to,
        uint256 amount
    ) external onlyRole("OPERATOR_ROLE") returns (bool) {
        require(
            totalSupply() + amount <= _maxSupply,
            "ERC20: Exceeds max supply"
        );
        _mint(to, amount);
        return true;
    }
}