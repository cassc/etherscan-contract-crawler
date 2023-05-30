// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IForex.sol";

contract Forex is IForex, AccessControl, ERC20 {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyOperator() {
        require(
            hasRole(OPERATOR_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender),
            "FOREX: caller not an operator"
        );
        _;
    }

    function mint(address account, uint256 amount)
        external
        override
        onlyOperator
    {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount)
        external
        override
        onlyOperator
    {
        _burn(account, amount);
    }
}