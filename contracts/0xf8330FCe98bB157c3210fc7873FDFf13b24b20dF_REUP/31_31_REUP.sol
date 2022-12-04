// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeUUPSERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREUP.sol";

contract REUP is BridgeUUPSERC20, UpgradeableBase(1), IREUP
{
    bool public constant isREUP = true;
    string public constant url = "https://reup.cash";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        UUPSERC20(_name, _symbol, 18)
    {    
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUP(newImplementation).isREUP());
        BridgeUUPSERC20.checkUpgrade(newImplementation);
    }

    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount)
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}