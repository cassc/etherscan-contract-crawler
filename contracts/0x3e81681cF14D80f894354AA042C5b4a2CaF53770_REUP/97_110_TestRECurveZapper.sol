// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../RECurveZapper.sol";

contract TestRECurveZapper is RECurveZapper
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(ICurveGauge _gauge, IREStablecoins _stablecoins, IRECurveBlargitrage _blargitrage)
        RECurveZapper(_gauge, _stablecoins, _blargitrage)
    {    
    }
}