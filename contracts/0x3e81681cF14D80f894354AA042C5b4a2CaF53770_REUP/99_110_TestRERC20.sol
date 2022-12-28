// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/RERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestRERC20 is RERC20("Test Token", "TST", 18), UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
    
    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }

    function checkUpgradeBase(address newImplementation) internal override view {}
    function mintDirect(address user, uint256 amount) public { mintCore(user, amount); }
    function burnDirect(address user, uint256 amount) public { burnCore(user, amount); }
}