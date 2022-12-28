// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REWardSplitter.sol";

contract TestREWardSplitter is REWardSplitter
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
}