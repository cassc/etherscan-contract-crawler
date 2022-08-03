// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";


contract GoalToken is ERC20Pausable, AccessControl, Ownable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(address[] memory operators) ERC20("GOAL", "GOAL") {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < operators.length; i++) {
            require(operators[i] != address(0), "Can't add a null address as operator");
            _setupRole(OPERATOR_ROLE, operators[i]);
        }
    }

    modifier onlyOwnerOrOperator() {
        require(
            hasRole(OPERATOR_ROLE, msg.sender) || msg.sender == owner(),
            "Function can only be called by owner or operator"
        );
        _;
    }

    function mint(address to, uint256 amount)
        external
        onlyOwnerOrOperator
    {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount)
        external
        onlyOwnerOrOperator
    {
        _burn(account, amount);
    }

    function pause() external onlyOwnerOrOperator {
        _pause();
    }

    function unpause() external onlyOwnerOrOperator {
        _unpause();
    }
}