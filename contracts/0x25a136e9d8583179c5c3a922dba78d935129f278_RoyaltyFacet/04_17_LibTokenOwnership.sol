// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {LibDiamond} from "./LibDiamond.sol";
import {IERC721} from "../interfaces/IERC721.sol";

library LibTokenOwnership {
    function ownerOf(uint256 _tokenId) internal view returns (address) {
        bytes memory functionCall = abi.encodeWithSelector(IERC721.ownerOf.selector, _tokenId);
        (bool success, bytes memory returndata) = address(this).staticcall(functionCall);
        if(success == false) {
            if(returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("Function call reverted");
            }
        }
        return abi.decode(returndata, (address));
    }

    function delegatedOwnerOf(uint256 _tokenId) internal returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address facet = ds.selectorToFacetAndPosition[IERC721.ownerOf.selector].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        bytes memory functionCall = abi.encodeWithSelector(IERC721.ownerOf.selector, _tokenId);
        (bool success, bytes memory returndata) = address(facet).delegatecall(functionCall); // solhint-disable-line
        if(success == false) {
            if(returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("Function call reverted");
            }
        }
        return abi.decode(returndata, (address));
    }
}