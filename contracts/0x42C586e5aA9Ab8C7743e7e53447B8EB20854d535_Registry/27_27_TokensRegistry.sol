// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./RegistryBase.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/registry/ITokensRegistry.sol";

abstract contract TokensRegistry is RegistryBase, ITokensRegistry {
    // CONSTANTS

    /// @dev Whitelisted token role
    bytes32 public constant WHITELISTED_TOKEN_ROLE =
        keccak256("WHITELISTED_TOKEN");

    // PUBLIC FUNCTIONS

    function whitelistTokens(address[] calldata tokens)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            _grantRole(WHITELISTED_TOKEN_ROLE, tokens[i]);
        }
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Check if token is whitelisted
     * @param token Token
     * @return Is token whitelisted
     */
    function isTokenWhitelisted(address token) external view returns (bool) {
        return hasRole(WHITELISTED_TOKEN_ROLE, token);
    }
}