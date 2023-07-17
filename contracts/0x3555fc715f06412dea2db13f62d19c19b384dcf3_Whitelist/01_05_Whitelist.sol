// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IWhitelist.sol";
import "../utils/DataTypes.sol";

/// @title NF3 Vault
/// @author NF3 Exchange
/// @notice This contract inherits from IWhitelist interface.
/// @dev This contract has all the functions related whitelisting of tokens on NF3 platform

contract Whitelist is Ownable, IWhitelist {
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice mapping of token addresses and their Types
    mapping(address => AssetType) public types;

    /// -----------------------------------------------------------------------
    /// User Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IWhitelist
    function checkAssetsWhitelist(Assets calldata _assets)
        external
        view
        override
    {
        uint256 len = _assets.tokens.length;
        uint256 i;
        // loop through NFTs and check their type
        for (i = 0; i < len; i++) {
            AssetType _type = types[_assets.tokens[i]];
            if (!(_type == AssetType.ERC_721 || _type == AssetType.ERC_1155))
                revert WhitelistError(WhitelistErrorCodes.INVALID_ITEM);
        }

        len = _assets.paymentTokens.length;
        // loop through FTs and check their type
        for (i = 0; i < len; i++) {
            AssetType _type = types[_assets.paymentTokens[i]];
            if (!(_type == AssetType.ERC_20 || _type == AssetType.ETH))
                revert WhitelistError(WhitelistErrorCodes.INVALID_ITEM);
        }
    }

    /// @notice Inherit from IWhitelist
    function getAssetsTypes(Assets calldata _assets)
        external
        view
        override
        returns (AssetType[] memory, AssetType[] memory)
    {
        uint256 len = _assets.tokens.length;
        // loop through NFTs, check their types and store them
        AssetType[] memory nftType = new AssetType[](len);
        uint256 i;
        for (i = 0; i < len; i++) {
            AssetType _type = types[_assets.tokens[i]];
            nftType[i] = _type;
            if (_type == AssetType.INVALID)
                revert WhitelistError(WhitelistErrorCodes.INVALID_ITEM);
        }

        len = _assets.paymentTokens.length;
        // loop through FTs, check their types and store them
        AssetType[] memory ftType = new AssetType[](len);
        for (i = 0; i < len; i++) {
            AssetType _type = types[_assets.paymentTokens[i]];
            ftType[i] = _type;
            if (ftType[i] == AssetType.INVALID)
                revert WhitelistError(WhitelistErrorCodes.INVALID_ITEM);
        }

        return (nftType, ftType);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from IWhitelist
    function setTokenTypes(
        address[] calldata _tokens,
        AssetType[] calldata _types
    ) external override onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            types[_tokens[i]] = _types[i];
        }
        emit TokensTypeSet(_tokens, _types);
    }
}