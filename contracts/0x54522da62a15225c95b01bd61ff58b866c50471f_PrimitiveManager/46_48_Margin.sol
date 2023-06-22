// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

import "@primitivefi/rmm-core/contracts/libraries/SafeCast.sol";

/// @author  Primitive
/// @notice  Utils functions to manage margins
/// @dev     Uses a data struct with two uint128s to optimize for one storage slot
library Margin {
    using SafeCast for uint256;

    struct Data {
        uint128 balanceRisky; // Balance of the risky token, aka underlying asset
        uint128 balanceStable; // Balance of the stable token, aka "quote" asset
    }

    /// @notice             Adds to risky and stable token balances
    /// @param  margin      Margin data of an account in storage to manipulate
    /// @param  delRisky    Amount of risky tokens to add to margin
    /// @param  delStable   Amount of stable tokens to add to margin
    function deposit(
        Data storage margin,
        uint256 delRisky,
        uint256 delStable
    ) internal {
        if (delRisky != 0) margin.balanceRisky += delRisky.toUint128();
        if (delStable != 0) margin.balanceStable += delStable.toUint128();
    }

    /// @notice             Removes risky and stable token balance from an internal margin account
    /// @param  margin      Margin data of an account in storage to manipulate
    /// @param  delRisky    Amount of risky tokens to subtract from margin
    /// @param  delStable   Amount of stable tokens to subtract from margin
    function withdraw(
        Data storage margin,
        uint256 delRisky,
        uint256 delStable
    ) internal {
        if (delRisky != 0) margin.balanceRisky -= delRisky.toUint128();
        if (delStable != 0) margin.balanceStable -= delStable.toUint128();
    }
}