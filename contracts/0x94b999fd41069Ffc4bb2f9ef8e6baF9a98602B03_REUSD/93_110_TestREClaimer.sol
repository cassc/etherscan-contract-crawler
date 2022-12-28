// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REClaimer.sol";

contract TestREClaimer is REClaimer
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }
}