// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/BridgeRERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestBridgeRERC20 is BridgeRERC20, UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() 
        RERC20("Test Token", "TST", 18) 
    {        
    }

    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }
    
    function checkUpgradeBase(address newImplementation) internal override view {}
    function getMinterOwner() internal override view returns (address) { return owner(); }
}