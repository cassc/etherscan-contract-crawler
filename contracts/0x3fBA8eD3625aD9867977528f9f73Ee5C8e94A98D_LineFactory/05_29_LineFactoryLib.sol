// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {SecuredLine} from "../modules/credit/SecuredLine.sol";
import {LineLib} from "./LineLib.sol";

library LineFactoryLib {
    error ModuleTransferFailed(address line, address spigot, address escrow);
    error InitNewLineFailed(address line, address spigot, address escrow);

    /**
     * @notice  - transfer ownership of Spigot + Escrow contracts from factory to line contract after all 3 have been deployed
     * @param line    - the line to transfer modules to
     * @param spigot  - the module to be transferred to line
     * @param escrow  - the module to be transferred to line
     */
    function transferModulesToLine(address line, address spigot, address escrow) external {
        (bool success, bytes memory returnVal) = spigot.call(
            abi.encodeWithSignature("updateOwner(address)", address(line))
        );
        (bool success2, bytes memory returnVal2) = escrow.call(
            abi.encodeWithSignature("updateLine(address)", address(line))
        );

        // ensure all modules were transferred
        if (!(success && abi.decode(returnVal, (bool)) && success2 && abi.decode(returnVal2, (bool)))) {
            revert ModuleTransferFailed(line, spigot, escrow);
        }

        SecuredLine(payable(line)).init();
    }

    /**
     * @notice  - See SecuredLine.constructor(). Deploys a new SecuredLine contract with params provided by factory.
     * @dev     - Deploy from lib not factory so we can have multiple factories (aka marketplaces) built on same Line contracts
     * @return line   - address of newly deployed line
     */
    function deploySecuredLine(
        address oracle,
        address arbiter,
        address borrower,
        address payable swapTarget,
        address s,
        address e,
        uint256 ttl,
        uint8 revenueSplit
    ) external returns (address) {
        return address(new SecuredLine(oracle, arbiter, borrower, swapTarget, s, e, ttl, revenueSplit));
    }
}