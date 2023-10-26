// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { LibStorage as s } from "./libraries/LibStorage.sol";

import "../utils/Errors.sol";
import "./Storage.sol";

/// @title DiamondProxy
/// @author Angle Labs, Inc.
/// @notice Implementation of a Diamond Proxy
/// @dev Reference: EIP-2535 Diamonds
/// @dev Forked from https://github.com/mudgen/diamond-3/blob/master/contracts/Diamond.sol by mudgen
contract DiamondProxy {
    constructor(FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) payable {
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                       FALLBACK                                                     
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @dev 1. Find the facet for the function that is called.
    /// @dev 2. Delegate the execution to the found facet via `delegatecall`.
    fallback() external payable {
        DiamondStorage storage ds = s.diamondStorage();
        // Get facet from function selector
        address facetAddress = ds.selectorInfo[msg.sig].facetAddress;
        if (facetAddress == address(0)) {
            revert FunctionNotFound(msg.sig);
        }

        assembly {
            // The pointer to the free memory slot
            let ptr := mload(0x40)
            // Copy function signature and arguments from calldata at zero position into memory at pointer position
            calldatacopy(ptr, 0, calldatasize())
            // Delegatecall method of the implementation contract returns 0 on error
            let result := delegatecall(gas(), facetAddress, ptr, calldatasize(), 0, 0)
            // Get the size of the last return data
            let size := returndatasize()
            // Copy the size length of bytes from return data at zero position to pointer position
            returndatacopy(ptr, 0, size)
            // Depending on the result value
            switch result
            case 0 {
                // End execution and revert state changes
                revert(ptr, size)
            }
            default {
                // Return data with length of size at pointers position
                return(ptr, size)
            }
        }
    }
}