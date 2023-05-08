// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";
import {DiamondStorage} from "./DiamondStorage.sol";
import {IDiamondCut} from "./IDiamondCut.sol";
import {FacetCut, FacetCutAction} from "./Facet.sol";

contract ABaseDiamond {
  // When no function exists for function called
  error FunctionNotFound(bytes4 functionSignature);

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable virtual {
    DiamondStorage storage ds;
    // get diamond storage
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
    // get facet from function selector
    address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
    if (facet == address(0)) revert FunctionNotFound(msg.sig);
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

  receive() external payable virtual {}
}