// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import {IStrategyMigrator} from "./interfaces/IStrategyMigrator.sol";
import {IFYToken} from "@yield-protocol/vault-v2/src/interfaces/IFYToken.sol";
import {IERC20} from "@yield-protocol/utils-v2/src/token/IERC20.sol";


/// @dev The Migrator contract poses as a Pool to receive all assets from a Strategy during an invest call.
/// TODO: For this to work, the implementing class must inherit from ERC20.
abstract contract StrategyMigrator is IStrategyMigrator {

    /// Mock pool base - Must match that of the calling strategy
    IERC20 public immutable base;

    /// Mock pool fyToken - Can be any address
    IFYToken public fyToken;

    /// Mock pool maturity - Can be set to a value far in the future to avoid `divest` calls
    uint32 public maturity;

    constructor(IERC20 base_, IFYToken fyToken_) {
        base = base_;
        fyToken = fyToken_;
    }

    /// @dev Mock pool init. Called within `invest`.
    function init(address)
        external
        virtual
        returns (uint256, uint256, uint256)
    {
        return (0, 0, 0);
    }

    /// @dev Mock pool burn that reverts so that `divest` never suceeds, but `eject` does.
    function burn(address, address, uint256, uint256)
        external
        virtual
        returns (uint256, uint256, uint256)
    {
        revert();
    }
}