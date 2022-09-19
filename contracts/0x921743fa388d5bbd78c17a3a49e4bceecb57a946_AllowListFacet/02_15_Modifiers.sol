// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {Shared} from "./Shared.sol";

abstract contract Modifiers is Context {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Check if role is admin or owner from AccessControl or DiamondStore contract owner. Need to clean up.
        require(
            Shared.hasRole(s.DEFAULT_ADMIN_ROLE, _msgSender()) ||
                Shared.hasRole(s.OWNER_ROLE, _msgSender()) ||
                _msgSender() == ds.contractOwner,
            "Modifiers: caller is not the owner"
        );
        _;
    }
}