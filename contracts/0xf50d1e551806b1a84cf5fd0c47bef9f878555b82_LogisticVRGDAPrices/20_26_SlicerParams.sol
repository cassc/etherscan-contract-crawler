// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISlicer.sol";

/**
 * @param slicer ISlicer instance
 * @param controller Address of slicer controller
 * @param transferTimelock The timestamp when the slicer becomes transferable
 * @param totalSupply Total supply of slices
 * @param royaltyPercentage Percentage of royalty to claim (up to 100, ie 10%)
 * @param flags Boolean flags in the following order from the right: [isCustomRoyaltyActive, isRoyaltyReceiverSlicer,
 * isResliceAllowed, isControlledTransferAllowed]
 * @param transferAllowlist Mapping from address to permission to transfer slices during transferTimelock period
 */
struct SlicerParams {
    ISlicer slicer;
    address controller;
    uint40 transferTimelock;
    uint32 totalSupply;
    uint8 royaltyPercentage;
    uint8 flags;
    uint8 FREE_SLOT_1;
    mapping(address => bool) transferAllowlist;
}