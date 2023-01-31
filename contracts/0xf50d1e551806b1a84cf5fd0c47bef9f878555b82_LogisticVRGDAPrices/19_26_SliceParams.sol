// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/Payee.sol";

/**
 * @param payees Addresses and shares of the initial payees
 * @param minimumShares Amount of shares that gives an account access to restricted
 * @param currencies Array of tokens accepted by the slicer
 * @param releaseTimelock The timestamp when the slicer becomes releasable
 * @param transferTimelock The timestamp when the slicer becomes transferable
 * @param controller The address of the slicer controller
 * @param slicerFlags See `_flags` in {Slicer}
 * @param sliceCoreFlags See `flags` in {SlicerParams} struct
 */
struct SliceParams {
    Payee[] payees;
    uint256 minimumShares;
    address[] currencies;
    uint256 releaseTimelock;
    uint40 transferTimelock;
    address controller;
    uint8 slicerFlags;
    uint8 sliceCoreFlags;
}