// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";

/// Liquidity Provider Whitelist.
///
/// This contract describes the concept of a whitelist for allowed Lps. RequestManager and FillManager
/// inherit from this contract.
contract LpWhitelist is Ownable {
    /// Emitted when a liquidity provider has been added to the set of allowed
    /// liquidity providers.
    ///
    /// .. seealso:: :sol:func:`addAllowedLp`
    event LpAdded(address lp);

    /// Emitted when a liquidity provider has been removed from the set of allowed
    /// liquidity providers.
    ///
    /// .. seealso:: :sol:func:`removeAllowedLp`
    event LpRemoved(address lp);

    /// The mapping containing addresses allowed to provide liquidity.
    mapping(address lp => bool allowed) public allowedLps;

    /// Modifier to check whether the passed address is an allowed LP
    modifier onlyAllowed(address addressToCheck) {
        require(allowedLps[addressToCheck], "Not allowed");
        _;
    }

    /// Add a liquidity provider to the set of allowed liquidity providers.
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param newLp The liquidity provider.
    function addAllowedLp(address newLp) public onlyOwner {
        allowedLps[newLp] = true;

        emit LpAdded(newLp);
    }

    /// Remove a liquidity provider from the set of allowed liquidity providers.
    ///
    /// .. note:: This function can only be called by the contract owner.
    ///
    /// @param oldLp The liquidity provider.
    function removeAllowedLp(address oldLp) public onlyOwner {
        delete allowedLps[oldLp];

        emit LpRemoved(oldLp);
    }
}