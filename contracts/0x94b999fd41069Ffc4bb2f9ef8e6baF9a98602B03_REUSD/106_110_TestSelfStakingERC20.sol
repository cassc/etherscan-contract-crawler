// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/SelfStakingERC20.sol";
import "../Base/UpgradeableBase.sol";

contract TestSelfStakingERC20 is SelfStakingERC20, UpgradeableBase(1)
{
    uint256 nextContractVersion;
    function contractVersion() public override(UUPSUpgradeableVersion, IUUPSUpgradeableVersion) view returns (uint256) { return nextContractVersion; }
    function setContractVersion(uint256 version) public { nextContractVersion = version; }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken)
        SelfStakingERC20(_rewardToken, "Test Token", "TST", 18)
    {}

    function mint(uint256 amount) public 
    {
        mintCore(msg.sender, amount);
    }

    function burn(uint256 amount) public 
    {
        burnCore(msg.sender, amount);
    }

    function checkUpgradeBase(address newImplementation) internal override view { SelfStakingERC20.checkUpgrade(newImplementation); }
    function getSelfStakingERC20Owner() internal override view returns (address) { return owner(); }
    function _checkUpgrade(address newImplementation) public view { checkUpgrade(newImplementation); }
}