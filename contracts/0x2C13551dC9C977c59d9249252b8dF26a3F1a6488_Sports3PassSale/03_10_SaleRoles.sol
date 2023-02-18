// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { AdminRole } from "./roles/AdminRole.sol";
import { FinancialRole } from "./roles/FinancialRole.sol";
import { OperatorRole } from "./roles/OperatorRole.sol";

contract SaleRoles is Pausable, AdminRole, OperatorRole, FinancialRole {
    function transferAdmin(address newAdmin) external virtual onlyAdmin {
        _transferAdmin(newAdmin);
    }

    function transferOperator(address newOperator) external virtual onlyAdmin {
        _transferOperator(newOperator);
    }

    function transferFinancial(address newFinancial)
        external
        virtual
        onlyAdmin
    {
        _transferFinancial(newFinancial);
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }
}