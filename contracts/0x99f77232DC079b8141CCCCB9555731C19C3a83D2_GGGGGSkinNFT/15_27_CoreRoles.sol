// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AdminRole } from "./roles/AdminRole.sol";
import { OperatorRole } from "./roles/OperatorRole.sol";

contract CoreRoles is Ownable, AdminRole, OperatorRole {
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyAdmin
    {
        require(newOwner != address(0), "invalid address");
        _transferOwnership(newOwner);
    }

    function transferOperator(address newOperator) external virtual onlyAdmin {
        _transferOperator(newOperator);
    }

    function transferAdmin(address newAdmin) external virtual onlyAdmin {
        _transferAdmin(newAdmin);
    }
}