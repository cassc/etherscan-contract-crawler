// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IAccessControlVF} from "../../access/IAccessControlVF.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract AccessControlVFExtension is Context, IERC165 {
    //Contract for function access control
    IAccessControlVF private _controlContract;

    constructor(address controlContractAddress) {
        _controlContract = IAccessControlVF(controlContractAddress);
    }

    modifier onlyRole(bytes32 role) virtual {
        _controlContract.checkRole(role, _msgSender());
        _;
    }

    modifier onlyRoles(bytes32[] memory roles) virtual {
        bool hasRequiredRole = false;
        for (uint256 i; i < roles.length; i++) {
            bytes32 role = roles[i];
            if (_controlContract.hasRole(role, _msgSender())) {
                hasRequiredRole = true;
                break;
            }
        }
        require(hasRequiredRole, "Missing required role");
        _;
    }

    function getAdminRole() public view returns (bytes32) {
        return _controlContract.getAdminRole();
    }

    function getMinterRoles() public view returns (bytes32[] memory) {
        return _controlContract.getMinterRoles();
    }

    function getBurnerRole() public view returns (bytes32) {
        return _controlContract.getBurnerRole();
    }

    /**
     * @dev Update the access control contract
     *
     * Requirements:
     *
     * - the caller must be an admin role
     * - `controlContractAddress` must support the IVFAccesControl interface
     */
    function setControlContract(address controlContractAddress)
        external
        onlyRole(_controlContract.getAdminRole())
    {
        require(
            IERC165(controlContractAddress).supportsInterface(
                type(IAccessControlVF).interfaceId
            ),
            "Contract does not support required interface"
        );
        _controlContract = IAccessControlVF(controlContractAddress);
    }
}