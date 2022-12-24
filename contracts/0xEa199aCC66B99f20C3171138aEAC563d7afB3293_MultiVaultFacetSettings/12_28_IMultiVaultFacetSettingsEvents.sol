// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";


interface IMultiVaultFacetSettingsEvents {
    event UpdateBridge(address bridge);
    event UpdateConfiguration(IMultiVaultFacetTokens.TokenType _type, int128 wid, uint256 addr);
    event UpdateRewards(int128 wid, uint256 addr);

    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event NewPendingGovernance(address governance);
    event UpdateGuardian(address guardian);

    event EmergencyShutdown(bool active);
}