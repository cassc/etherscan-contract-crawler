// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import {IDiamondCutCommon} from "./IDiamondCutCommon.sol";

/// @title ERCXXX Diamond Standard, Diamond Cut Batch Init extension.
/// @dev See https://eips.ethereum.org/EIPS/eip-XXXX
/// @dev Note: the ERC-165 identifier for this interface is 0xb2afc5b5
interface IDiamondCutBatchInit is IDiamondCutCommon {
    /// @notice Add/replace/remove facet functions and execute a batch of functions with delegatecall.
    /// @dev Emits a {DiamondCut} event.
    /// @param cuts The list of facet addresses, actions and function selectors to apply to the diamond.
    /// @param initializations The list of addresses and encoded function calls to execute with delegatecall.
    function diamondCut(FacetCut[] calldata cuts, Initialization[] calldata initializations) external;
}