// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import {IDiamondCutCommon} from "./IDiamondCutCommon.sol";

/// @title ERC2535 Diamond Standard, Diamond Cut.
/// @dev See https://eips.ethereum.org/EIPS/eip-2535
/// @dev Note: the ERC-165 identifier for this interface is 0x1f931c1c
interface IDiamondCut is IDiamondCutCommon {
    /// @notice Add/replace/remove facet functions and optionally execute a function with delegatecall.
    /// @dev Emits a {DiamondCut} event.
    /// @param cuts The list of facet addresses, actions and function selectors to apply to the diamond.
    /// @param target The address of the contract to execute `data` on.
    /// @param data The encoded function call to execute on `target`.
    function diamondCut(FacetCut[] calldata cuts, address target, bytes calldata data) external;
}