// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REStablecoins.sol";

contract TestREStablecoins is REStablecoins
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(StablecoinConfig memory _stablecoin1, StablecoinConfig memory _stablecoin2, StablecoinConfig memory _stablecoin3)
        REStablecoins(_stablecoin1, _stablecoin2, _stablecoin3)
    {        
    }

    function getStablecoin1() external view returns (StablecoinConfig memory) { return supportedStablecoins()[0].config; }
    function getStablecoin2() external view returns (StablecoinConfig memory) { return supportedStablecoins()[1].config; }
    function getStablecoin3() external view returns (StablecoinConfig memory) { return supportedStablecoins()[2].config; }
}