// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../RECurveMintedRewards.sol";

contract TestRECurveMintedRewards is RECurveMintedRewards
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICanMint _rewardToken, ICurveGauge _gauge)
        RECurveMintedRewards(_rewardToken, _gauge)
    {        
    }

    function sendRewardsTwice(uint256 units)
        public
    {
        sendRewards(units);
        sendRewards(units);
    }
}