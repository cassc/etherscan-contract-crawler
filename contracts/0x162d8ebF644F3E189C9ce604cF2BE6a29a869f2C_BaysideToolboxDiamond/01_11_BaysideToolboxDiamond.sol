// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LibDiamond.sol";
import "./facets/DiamondCutAndLoupeFacet.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract BaysideToolboxDiamond {

    constructor (
        address _diamondCutAndLoupeFacetAddress,
        address signingAddress,
        address multisigWallet,
        string memory baseTokenURI,
        address methodsExposureFacetAddress) {
        LibDiamond.setContractOwner(msg.sender);

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesBasisPoints = 750;
        _as.royaltiesRecipient = multisigWallet;
        _as.signingAddress = signingAddress;
        _as.maxMintsPerWallet = 1;
        _as.maxSupply = 600;
        _as.baseTokenURI = baseTokenURI;
        _as.maxMintsTeam = 45;
        _as.mintPrice = 0.15 ether;
        _as.methodsExposureFacetAddress = methodsExposureFacetAddress;
        _as.seaportAddress = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IERC2981).interfaceId] = true;

        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = DiamondCutAndLoupeFacet.diamondCut.selector;
        selectors[1] = DiamondCutAndLoupeFacet.facets.selector;
        selectors[2] = DiamondCutAndLoupeFacet.facetFunctionSelectors.selector;
        selectors[3] = DiamondCutAndLoupeFacet.facetAddresses.selector;
        selectors[4] = DiamondCutAndLoupeFacet.facetAddress.selector;
        selectors[5] = DiamondCutAndLoupeFacet.supportsInterface.selector;

        LibDiamond.addReplaceRemoveFacetSelectors(0, 0, _diamondCutAndLoupeFacetAddress, IDiamondCut.FacetCutAction.Add, selectors);
    }

    function implementation() public view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.methodsExposureFacetAddress;
    }

    // =========== Lifecycle ===========

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

    /*
        @dev
        To enable receiving ETH
    */
    receive() external payable {}
}