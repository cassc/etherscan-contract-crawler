// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";

import "./interfaces/IERC721Enumerable.sol";

import "./libraries/DiamondLib.sol";

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { DiamondLib } from "./libraries/DiamondLib.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { IERC173 } from "./interfaces/IERC173.sol";
import { MetadataContract } from "./interfaces/IMetadata.sol";

contract Diamond is IERC165, IDiamondCut, IDiamondLoupe, Initializable, IERC173 {


    function initialize(
        address _owner, 
        DiamondSettings memory params,
        IDiamondCut.FacetCut[] memory _facets,
        address diamondInit,
        bytes calldata _calldata
    ) public initializer {
        LibDiamond.diamondStorage().supportedInterfaces[type(IERC165).interfaceId] = true;
        LibDiamond.diamondStorage().supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        LibDiamond.diamondStorage().supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        LibDiamond.diamondStorage().supportedInterfaces[type(IERC173).interfaceId] = true;
        LibDiamond.diamondStorage().supportedInterfaces[type(IERC721).interfaceId] = true;
        LibDiamond.diamondStorage().supportedInterfaces[type(IERC721Metadata).interfaceId] = true;

        // initialize the diamond
        LibDiamond.diamondCut(_facets, diamondInit, _calldata);

        // set the symbol and name of the diamond
        DiamondLib.diamondStorage().diamondContract.settings.owner = _owner;
        DiamondLib.diamondStorage().diamondContract.metadata['symbol'] = params.symbol;
        DiamondLib.diamondStorage().diamondContract.metadata['name'] = params.name;

        IERC173(address(this)).transferOwnership(params.owner);
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external override view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return type(IERC165).interfaceId == _interfaceId 
            || type(IERC721).interfaceId == _interfaceId 
            || type(IERC721Metadata).interfaceId == _interfaceId 
            || type(IERC721Enumerable).interfaceId == _interfaceId 
            || ds.supportedInterfaces[_interfaceId];
    }

    /// @notice transfer ownership to new contract
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    /// @notice get a address to the owner of the contract
    function owner() external override view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
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
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
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