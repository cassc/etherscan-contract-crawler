// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {LibAppStorage} from "../libraries/storage/LibAppStorage.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  BaseStorage
 * @author slvrfn
 * @notice Abstract contract which contains the shared AppStorage values.
 * @dev    This contract is meant to be inherited by contracts so they can use the shared AppStorage values.
 *         This contract should always be inherited from FIRST in order to preserve the AppStorage struct being stored
 *         at position 0 in consuming contracts.
 */
abstract contract BaseStorage {
    LibAppStorage.AppStorage internal s;
}