// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";


interface IMultiVaultFacetSettingsEvents {
    event UpdateBridge(address bridge);
    event UpdateConfiguration(IMultiVaultFacetTokens.TokenType _type, int128 wid, uint256 addr);
    event UpdateRewards(int128 wid, uint256 addr);
    event UpdateWeth(address weth);
    event UpdateGasDonor(address gasDonor);
    event UpdateCustom(int8 wid, uint256 addr, address token);

    event UpdateDailyWithdrawalLimits(address token, uint limit);
    event UpdateUndeclaredWithdrawalLimits(address token, uint limit);
    event UpdateWithdrawalLimitStatus(address token, bool status);

    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event NewPendingGovernance(address governance);
    event UpdateGuardian(address guardian);
    event UpdateWithdrawGuardian(address withdrawGuardian);

    event EmergencyShutdown(bool active);
}