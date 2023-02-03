// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../REYIELD.sol";

contract TestREYIELD is REYIELD
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol)
        REYIELD(_rewardToken, _name, _symbol)
    {
    }
}