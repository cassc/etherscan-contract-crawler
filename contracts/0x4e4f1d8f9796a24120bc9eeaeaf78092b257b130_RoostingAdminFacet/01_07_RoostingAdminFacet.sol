// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibRoosting } from "../libraries/LibRoosting.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract RoostingAdminFacet {
    event RoostingAdminChange(address admin, bool isAdmin);

    function addRoostingAdmin(address admin) external {
        LibDiamond.enforceIsContractOwner();

        LibRoosting.roostingStorage().roostingAdmins[admin] = true;
        emit RoostingAdminChange(admin, true);
    }

    function removeRoostingAdmin(address admin) external {
        LibDiamond.enforceIsContractOwner();

        LibRoosting.roostingStorage().roostingAdmins[admin] = false;
        emit RoostingAdminChange(admin, false);
    }

    function isRoostingAdmin(address admin) external view returns (bool) {
        return LibRoosting.roostingStorage().roostingAdmins[admin];
    }
}