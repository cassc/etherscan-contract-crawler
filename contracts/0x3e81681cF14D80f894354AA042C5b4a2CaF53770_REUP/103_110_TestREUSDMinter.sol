// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REUSDMinter.sol";

contract TestREUSDMinter is REUSDMinter
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _REUSD, IREStablecoins _stablecoins)
        REUSDMinter(_custodian, _REUSD, _stablecoins)
    {        
    }
}