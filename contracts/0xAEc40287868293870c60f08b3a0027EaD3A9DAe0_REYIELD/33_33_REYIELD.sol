// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeSelfStakingERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREYIELD.sol";

contract REYIELD is BridgeSelfStakingERC20, UpgradeableBase(1), IREYIELD
{
    bool public constant isREYIELD = true;
    string public constant url = "https://reup.cash";
    
   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _rewardToken, string memory _name, string memory _symbol)
        SelfStakingERC20(_rewardToken, _name, _symbol, 18)
    {
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREYIELD(newImplementation).isREYIELD());
        BridgeSelfStakingERC20.checkUpgrade(newImplementation);
    }

    function getSelfStakingERC20Owner() internal override view returns (address) { return owner(); }
    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount) 
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}