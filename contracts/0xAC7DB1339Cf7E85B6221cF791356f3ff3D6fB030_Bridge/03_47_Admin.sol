//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Getters.sol";
import "./Setters.sol";

/// @title Admin
/// @notice This contract exposes methods to carry out administrative tasks not handled by governance.
/// These methods are used for configuring the token mappings, enabling/disabling token bridges and pausing/unpausing bridge out operations.
/// @author Piotr "pibu" Buda
contract Admin is Getters, Setters {
    event BridgeInitialized(bytes tokenClassKey, address indexed token, uint256 baseType, TokenType tokenType, bool isburning);
    event ConversionInitialized(address indexed token, uint256 baseType, bytes tokenClassKey);
    event EnabledUpdated(bytes tokenClassKey, bool isEnabled);

    /// @notice Allows to setup a token bridge between this chain and the hub chain. This is a two-way bridge allowing
    /// to bridge tokens in and out of this EVM chain.
    /// @param tokenClassKey the token class key in the hub chain, uniquely identifying the token there
    /// @param token contract address of the EVM token
    /// @param baseType the base type (which is used to build token ids) of the EVM token
    /// @param tokenType the type of the EVM token (ERC20, ERC721 or ERC1155)
    /// @param burning whether the token bridge should work in the burning (true) or locking (false) mode
    /// @param enabled whether the token bridge should be enabled immediately (true) or not (false)
    function setupTokenBridge(
        bytes memory tokenClassKey,
        address token,
        uint256 baseType,
        TokenType tokenType,
        bool burning,
        bool enabled
    ) external onlyOwner {
        require(tokenClassKey.length > 0, "INVALID_TOKEN_CLASS_KEY");
        require(!isInitialized(tokenClassKey), "BRIDGE_INITIALIZED");
        require(token != address(0), "INVALID_TOKEN");
        require(tokenType != TokenType.UNKNOWN, "INVALID_TOKEN_TYPE");

        setTokenBridge(
            Structs.TokenBridge({tokenClassKey: tokenClassKey, initialized: true, burning: burning, enabled: enabled, token: token, baseType: baseType}),
            tokenType
        );

        emit BridgeInitialized(tokenClassKey, token, baseType, tokenType, burning);
        emit EnabledUpdated(tokenClassKey, enabled);
    }

    /// @notice Allows to setup a conversion funnel. This mechanism allows to bridge out tokens from this EVM chain from multiple contracts
    /// to a single token in the hub chain.
    /// @param token contract address of the EVM token
    /// @param baseType the base type (which is used to build token ids) of the EVM token
    /// @param tokenClassKey the token class key in the hub chain, uniquely identifying the token there
    function setupConversionFunnel(
        address token,
        uint256 baseType,
        bytes memory tokenClassKey
    ) external onlyOwner {
        require(token != address(0), "INVALID_TOKEN");
        require(tokenClassKey.length > 0, "INVALID_TOKEN_CLASS_KEY");
        address originalToken = getToken(tokenClassKey);
        setConversionFunnel(token, baseType, tokenClassKey, getTokenType(originalToken));
        emit ConversionInitialized(token, baseType, tokenClassKey);
    }

    /// @notice Sets the enabled flag for token bridge.
    /// @param tokenClassKey the token class key for which the enabled flag should be toggled
    /// @param enabled a flag indication whether to set the bridge as enabled or not
    function setTokenBridgeEnabled(bytes memory tokenClassKey, bool enabled) external onlyOwner {
        //use the getter to verify the enabled flag can be set on it
        require(isInitialized(tokenClassKey), "NOT_INITIALIZED");

        setEnabled(tokenClassKey, enabled);

        emit EnabledUpdated(tokenClassKey, enabled);
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }
}