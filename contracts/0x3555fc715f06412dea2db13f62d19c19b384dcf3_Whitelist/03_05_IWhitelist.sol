// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../utils/DataTypes.sol";

/// @title NF3 Swap Interface
/// @author NF3 Exchange
/// @dev This interface defines all the functions related to whitelisting of tokens

interface IWhitelist {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum WhitelistErrorCodes {
        INVALID_ITEM
    }

    error WhitelistError(WhitelistErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when new tokens are whitelisted and their types are set
    /// @param tokens addresses of tokens that are whitelisted
    /// @param types type of token set to
    event TokensTypeSet(address[] tokens, AssetType[] types);

    /// -----------------------------------------------------------------------
    /// User Actions
    /// -----------------------------------------------------------------------

    /// @dev Check if all the passed assets are whitelisted
    /// @param assets Assets to check on
    function checkAssetsWhitelist(Assets calldata assets) external view;

    /// @dev Check and return types of assets
    /// @param assets Assets to check on
    /// @return nftType types of nfts sent
    /// @return ftType types of fts sent
    function getAssetsTypes(Assets calldata assets)
        external
        view
        returns (AssetType[] memory, AssetType[] memory);

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set types of the tokens passed
    /// @param tokens Tokens to set
    /// @param types Types of tokens
    function setTokenTypes(
        address[] calldata tokens,
        AssetType[] calldata types
    ) external;
}