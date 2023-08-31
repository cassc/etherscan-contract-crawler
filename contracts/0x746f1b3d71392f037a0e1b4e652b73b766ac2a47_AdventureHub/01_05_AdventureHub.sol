// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibDiamond} from "src/libraries/diamond-core/LibDiamond.sol";
import {IDiamondCut} from "src/interfaces/diamond-core/IDiamondCut.sol";
import {IDiamondLoupe} from "src/interfaces/diamond-core/IDiamondLoupe.sol";
import "src/interfaces/diamond-core/IDiamond.sol";

/**
 * @title AdventureHub
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen) & Limit Break, Inc.
 * @notice Implementation of a Diamond to support EIP-2535
 */
contract AdventureHub is IDiamond {

    error FunctionNotFound(bytes4 _functionSelector);

    constructor(IDiamondCut.FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable {
        LibDiamond.setContractOwner(_args.owner);
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);

        // Code can be added here to perform actions and set state variables.
    }

    ///@dev Fallback function used to delegate call selectors on different facets
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert FunctionNotFound(msg.sig);
        }
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
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}