// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/decentraland/IDecentralandFacet.sol";

contract LandWorksDecentralandAdminOperatorUpdater {
    IDecentralandFacet immutable landWorks;

    constructor(address _landWorks) {
        landWorks = IDecentralandFacet(_landWorks);
    }

    function updateAssetsAdministrativeState(uint256[] memory _assets)
        external
    {
        for (uint256 i = 0; i < _assets.length; i++) {
            landWorks.updateAdministrativeState(_assets[i]);
        }
    }
}