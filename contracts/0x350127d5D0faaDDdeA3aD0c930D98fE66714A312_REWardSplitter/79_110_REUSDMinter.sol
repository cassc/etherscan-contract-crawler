// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./Base/UpgradeableBase.sol";
import "./IREUSDMinter.sol";
import "./Base/REUSDMinterBase.sol";

/**
    Lets people directly mint REUSD
 */
contract REUSDMinter is REUSDMinterBase, UpgradeableBase(3), IREUSDMinter
{
    bool public constant isREUSDMinter = true;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _REUSD, IREStablecoins _stablecoins)
        REUSDMinterBase(_custodian, _REUSD, _stablecoins)
    {
    }

    function checkUpgradeBase(address newImplementation)
        internal
        override
        view
    {
        assert(IREUSDMinter(newImplementation).isREUSDMinter());
    }

    function mint(IERC20 paymentToken, uint256 reusdAmount)
        public
    {
        mintREUSDCore(msg.sender, paymentToken, msg.sender, reusdAmount);
    }

    function mintPermit(IERC20Full paymentToken, uint256 reusdAmount, uint256 permitAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
    {
        IERC20Permit(paymentToken).permit(msg.sender, address(this), permitAmount, deadline, v, r, s);
        mintREUSDCore(msg.sender, paymentToken, msg.sender, reusdAmount);
    }

    function mintTo(IERC20 paymentToken, address recipient, uint256 reusdAmount)
        public
    {
        mintREUSDCore(msg.sender, paymentToken, recipient, reusdAmount);
    }
}