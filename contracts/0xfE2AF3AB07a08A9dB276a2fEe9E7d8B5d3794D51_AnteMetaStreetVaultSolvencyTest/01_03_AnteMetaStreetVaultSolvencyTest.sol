// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../AnteTest.sol";

interface IVaultAbridged {
    enum TrancheId {
        Senior,
        Junior
    }

    function trancheState(TrancheId trancheId)
        external
        view
        returns (
            uint256 realizedValue,
            uint256 estimatedValue,
            uint256 pendingRedemptions,
            uint256 redemptionQueue,
            uint256 processedRedemptionQueue,
            uint256 depositSharePrice,
            uint256 redemptionSharePrice_
        );
}

// @title MetaStreet Vault Junior Tranche Solvency Test
// @notice Ante Test to check if a MetaStreet Vault's junior tranche is solvent
contract AnteMetaStreetVaultSolvencyTest is AnteTest("MetaStreet General-WETH Vault's Junior Tranche is solvent") {
    IVaultAbridged private vault;

    constructor(address _vault) {
        protocolName = "MetaStreet";
        testedContracts.push(_vault);

        vault = IVaultAbridged(_vault);
    }

    // @notice Check if a Vault's junior tranche is solvent
    // @return true if Vault's junior tranche is solvent, otherwise false
    function checkTestPasses() external view override returns (bool) {
        (uint256 realizedValue, , uint256 pendingRedemptions, , , , ) = vault.trancheState(
            IVaultAbridged.TrancheId.Junior
        );

        return realizedValue >= pendingRedemptions;
    }
}