// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IRedeemable} from "./UXDToken.sol";
import {IUXDRouter} from "./IUXDRouter.sol";

/// @title UXDControllerStorage
/// @notice Base storage contract for UXDController
/// @dev Defines storage layout for the UXDController contract
abstract contract UXDControllerStorage {

    /// @notice The token to be minted and burned
    IRedeemable public redeemable;

    /// @notice The router to the perpetual DEXes.
    IUXDRouter public router;

    /// @notice Mapping for tokens that are whitelisted to be used as collateral.
    /// @dev Mapping token address => is whitelisted
    mapping(address => bool) public whitelistedAssets;

    /// @dev the list of accepted collateral tokens
    address[] public assetList;

    /// weth address
    address public weth;
}