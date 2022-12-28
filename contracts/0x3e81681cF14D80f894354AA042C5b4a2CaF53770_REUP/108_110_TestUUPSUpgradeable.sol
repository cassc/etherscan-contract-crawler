// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../Base/UUPSUpgradeable.sol";

contract TestUUPSUpgradeable is UUPSUpgradeable
{
    error Nope();
    error Exploded();

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address public immutable self = address(this);
    
    bool canUpgrade;
    function setCanUpgrade(bool can) public { canUpgrade = can; }
    function beforeUpgrade(address) internal override view { if (!canUpgrade) { revert Nope(); } }

    function yayInitializer(bool explode)
        public
    {
        if (explode) 
        { 
            canUpgrade = true; // just to make it not a view function
            revert Exploded(); 
        }
    }

    function _() external {} // 0xb7ba4583
}