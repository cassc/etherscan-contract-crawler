// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SolidStateDiamond} from "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title Implementation of the SolidState "Diamond" proxy reference implementation.
 *
 * @dev Constructor has been overridden to accept address to set ERC-173 owner on contract creation.
 *
 * @notice This is a proxy contract that conforms to the ERC-2535 "Diamond" standard.
 */
contract Diamond is SolidStateDiamond {
    constructor(address owner) SolidStateDiamond() {
        _setOwner(owner);
    }
}