// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";

/**
 * @title Party
 * @author PartyFinance
 * @notice Diamond implementation of a Party
 * @dev Implements Nick Mudge's [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535)
 */
contract Party {
    constructor(address _diamondCutFacet) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // Set PartyFactory as contract owner (for making `diamondCut`)
        ds.contractOwner = msg.sender;
        // Add `diamondCut` method to Party (from DiamondCutFacet)
        ds.facets[IDiamondCut.diamondCut.selector] = bytes20(_diamondCutFacet);
        ds.selectorCount = 1;
        ds.selectorSlots[0] = bytes32(IDiamondCut.diamondCut.selector);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}