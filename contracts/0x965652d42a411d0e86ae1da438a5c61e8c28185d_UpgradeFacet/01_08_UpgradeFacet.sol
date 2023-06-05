// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {InternalOwnableRoles} from "../../internals/InternalOwnableRoles.sol";
import {BaseStorage} from "../../diamond/BaseStorage.sol";
import {INiftyKitAppRegistry} from "../../interfaces/INiftyKitAppRegistry.sol";
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";

contract UpgradeFacet is InternalOwnableRoles {
    function upgradeApps(
        bytes32[] calldata names
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        uint256 namesLength = names.length;
        for (uint256 i = 0; i < namesLength; i++) {
            _upgradeApp(names[i]);
        }
    }

    function _upgradeApp(bytes32 name) internal {
        BaseStorage.Layout storage layout = BaseStorage.layout();
        INiftyKitAppRegistry registry = INiftyKitAppRegistry(
            layout._niftyKit.appRegistry()
        );
        INiftyKitAppRegistry.App memory app = registry.getApp(name);
        require(app.version != 0, "UpgradeFacet: App does not exist");
        require(
            app.version > layout._apps[name].version,
            "UpgradeFacet: A newer version is already installed"
        );

        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](2);

        facetCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: layout._apps[name].selectors
        });
        facetCuts[1] = IDiamondCut.FacetCut({
            facetAddress: app.implementation,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: app.selectors
        });

        LibDiamond.diamondCut(facetCuts, address(0), "");
        layout._apps[name] = app;
    }
}