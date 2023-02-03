// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REStablecoins.sol";

contract TestREStablecoins is REStablecoins
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _stablecoin1, IERC20 _stablecoin2, IERC20 _stablecoin3)
        REStablecoins(_stablecoin1, _stablecoin2, _stablecoin3)
    {        
    }

    function getStablecoin1() external view returns (IERC20) { return supported()[0].token; }
    function getStablecoin2() external view returns (IERC20) { return supported()[1].token; }
    function getStablecoin3() external view returns (IERC20) { return supported()[2].token; }
}