// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {AccessControl} from "../../src/libraries/LibAccessControl.sol";

library AccessHelper {
    function allAccess() public pure returns (bytes32[] memory access) {
        access = new bytes32[](0);
    }

    function adminAccess() public pure returns (bytes32[] memory access) {
        access = new bytes32[](1);
        access[0] = AccessControl.DEFAULT_ADMIN_ROLE;
    }

    function minterAccess() public pure returns (bytes32[] memory access) {
        access = new bytes32[](2);
        access[0] = AccessControl.DEFAULT_ADMIN_ROLE;
        access[1] = AccessControl.MINTER_ROLE;
    }

    function managerAccess() public pure returns (bytes32[] memory access) {
        access = new bytes32[](2);
        access[0] = AccessControl.DEFAULT_ADMIN_ROLE;
        access[1] = AccessControl.MANAGER_ROLE;
    }

    function privateAccess() public pure returns (bytes32[] memory access) {
        access = new bytes32[](3);
        access[0] = AccessControl.DEFAULT_ADMIN_ROLE;
        access[1] = AccessControl.MINTER_ROLE;
        access[2] = AccessControl.MANAGER_ROLE;
    }

    function optInSecAccess() public pure returns (bytes32[] memory access) {
        access = new bytes32[](1);
        access[0] = AccessControl.SEC_MULTISIG_ROLE;
    }

    function payeeAccess() public pure returns (bytes32[] memory access) {
        access = new bytes32[](1);
        access[0] = AccessControl.PAYEE_ROLE;
    }
}