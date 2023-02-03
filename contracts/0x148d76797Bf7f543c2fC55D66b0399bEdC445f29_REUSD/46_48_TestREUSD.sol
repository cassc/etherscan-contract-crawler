// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REUSD.sol";

contract TestREUSD is REUSD
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        REUSD(_name, _symbol)
    {
    }
}