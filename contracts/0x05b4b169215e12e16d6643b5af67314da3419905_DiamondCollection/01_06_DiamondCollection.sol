// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {INiftyKitAppRegistry} from "../interfaces/INiftyKitAppRegistry.sol";
import {INiftyKitV3} from "../interfaces/INiftyKitV3.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {BaseStorage} from "./BaseStorage.sol";

contract DiamondCollection {
    constructor(INiftyKitV3.DiamondArgs memory args) {
        BaseStorage.Layout storage layout = BaseStorage.layout();
        layout._niftyKit = INiftyKitV3(msg.sender);
        INiftyKitAppRegistry registry = INiftyKitAppRegistry(
            layout._niftyKit.appRegistry()
        );
        INiftyKitAppRegistry.Base memory base = registry.getBase();
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](
            args.apps.length + 1
        );

        layout._treasury = args.treasury;
        layout._baseVersion = base.version;
        layout._baseURI = args.baseURI;
        layout._trustedForwarder = args.trustedForwarder;
        facetCuts = _appFacets(facetCuts, layout, registry, args.apps);
        facetCuts = _baseFacet(facetCuts, base);

        LibDiamond.diamondCut(
            facetCuts,
            base.implementation,
            abi.encodeWithSignature(
                "_initialize(address,address,string,string,address,uint16)",
                args.owner,
                args.admin,
                args.name,
                args.symbol,
                args.royalty,
                args.royaltyBps
            )
        );
    }

    function _appFacets(
        IDiamondCut.FacetCut[] memory facetCuts,
        BaseStorage.Layout storage layout,
        INiftyKitAppRegistry registry,
        bytes32[] memory apps
    ) internal returns (IDiamondCut.FacetCut[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 appsLength = apps.length;
        for (uint256 i = 0; i < appsLength; ) {
            INiftyKitAppRegistry.App memory app = registry.getApp(apps[i]);
            if (app.version == 0) revert("App does not exist");

            facetCuts[i] = IDiamondCut.FacetCut({
                facetAddress: app.implementation,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: app.selectors
            });

            ds.supportedInterfaces[app.interfaceId] = true;
            layout._apps[apps[i]] = app;

            unchecked {
                i++;
            }
        }

        return facetCuts;
    }

    function _baseFacet(
        IDiamondCut.FacetCut[] memory facetCuts,
        INiftyKitAppRegistry.Base memory base
    ) internal returns (IDiamondCut.FacetCut[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetCuts[facetCuts.length - 1] = IDiamondCut.FacetCut({
            facetAddress: base.implementation,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: base.selectors
        });

        uint256 idsLength = base.interfaceIds.length;
        for (uint256 i = 0; i < idsLength; ) {
            ds.supportedInterfaces[base.interfaceIds[i]] = true;

            unchecked {
                i++;
            }
        }

        return facetCuts;
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