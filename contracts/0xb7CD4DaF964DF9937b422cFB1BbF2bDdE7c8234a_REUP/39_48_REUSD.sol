// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/BridgeRERC20.sol";
import "./Base/UpgradeableBase.sol";
import "./IREUSD.sol";

/** REUSD = Real Estate USD, our stablecoin */
contract REUSD is BridgeRERC20, UpgradeableBase(3), IREUSD
{
    bool public constant isREUSD = true;
    string public constant url = "https://reup.cash";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol)
        RERC20(_name, _symbol, 18)
    {    
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUSD(newImplementation).isREUSD());
        BridgeRERC20.checkUpgrade(newImplementation);
    }

    function getMinterOwner() internal override view returns (address) { return owner(); }

    function mint(address to, uint256 amount)
        public
        onlyMinter
    {
        mintCore(to, amount);
    }
}