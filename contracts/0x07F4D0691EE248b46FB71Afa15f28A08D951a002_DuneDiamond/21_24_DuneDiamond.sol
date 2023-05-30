// SPDX-License-Identifier: UNLICENSED
// © 2022 [XXX]. All rights reserved.
pragma solidity ^0.8.13;

import { IDiamondCut, IDiamondLoupe, IERC173 } from "./Interfaces.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./Constants.sol";
import "./facets/DiamondCutAndLoupeFacet.sol";
import "./LibDiamond.sol";

/*
    @dev
    This contract is using the very robust and innovative EIP 2535 (https://eips.ethereum.org/EIPS/eip-2535) which
    allows a contract to be organized in the most efficient way
*/
contract DuneDiamond is BaseFacet {

    constructor(address _diamondCutAndLoupeFacetAddress) {
        // adding ERC165 data
        DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721).interfaceId] = true;
		ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
		ds.supportedInterfaces[type(IERC2981).interfaceId] = true;

		// Init appStorage
		AppStorage storage s = LibDiamond.appStorage();
		s.chapterId = 0;

		bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = DiamondCutAndLoupeFacet.diamondCut.selector;
        selectors[1] = DiamondCutAndLoupeFacet.facets.selector;
        selectors[2] = DiamondCutAndLoupeFacet.facetFunctionSelectors.selector;
        selectors[3] = DiamondCutAndLoupeFacet.facetAddresses.selector;
        selectors[4] = DiamondCutAndLoupeFacet.facetAddress.selector;
		selectors[5] = DiamondCutAndLoupeFacet.supportsInterface.selector;

        LibDiamond.addFunctions(_diamondCutAndLoupeFacetAddress, selectors);
    }

    // =========== Lifecycle ===========

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // To learn more about this implementation read EIP 2535
    fallback() external payable {
        address facet = LibDiamond.diamondStorage().selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    /*
        @dev
        To enable receiving ETH
    */
    receive() external payable {}
}