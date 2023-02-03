// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/UUPSUpgradeableVersion.sol";

contract TestUUPSUpgradeableVersion is UUPSUpgradeableVersion(123)
{
    uint256 nextContractVersion;
    function contractVersion() public override view returns (uint256) { return nextContractVersion == 0 ? super.contractVersion() : nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }

    error Nope();
    
    bool canUpgrade;
    function setCanUpgrade(bool can) public { canUpgrade = can; }
    function beforeUpgradeVersion(address) internal override view { if (!canUpgrade) { revert Nope(); } }
}