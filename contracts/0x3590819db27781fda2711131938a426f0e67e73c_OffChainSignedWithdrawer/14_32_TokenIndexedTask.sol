// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.3;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';

import '../interfaces/base/ITokenIndexedTask.sol';

/**
 * @dev Token indexed task. It defines a token acceptance list to tell which are the tokens supported by the
 * task. Tokens acceptance can be configured either as an allow list or as a deny list.
 */
abstract contract TokenIndexedTask is ITokenIndexedTask, Authorized {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Acceptance list type
    TokensAcceptanceType public override tokensAcceptanceType;

    // Enumerable set of tokens included in the acceptance list
    EnumerableSet.AddressSet internal _tokens;

    /**
     * @dev Token index config. Only used in the initializer.
     * @param acceptanceType Token acceptance type to be set
     * @param tokens List of token addresses to be set for the acceptance list
     */
    struct TokenIndexConfig {
        TokensAcceptanceType acceptanceType;
        address[] tokens;
    }

    /**
     * @dev Initializes the token indexed task. It does not call upper contracts initializers.
     * @param config Token indexed task config
     */
    function __TokenIndexedTask_init(TokenIndexConfig memory config) internal onlyInitializing {
        __TokenIndexedTask_init_unchained(config);
    }

    /**
     * @dev Initializes the token indexed task. It does call upper contracts initializers.
     * @param config Token indexed task config
     */
    function __TokenIndexedTask_init_unchained(TokenIndexConfig memory config) internal onlyInitializing {
        _setTokensAcceptanceType(config.acceptanceType);

        for (uint256 i = 0; i < config.tokens.length; i++) {
            _setTokenAcceptanceList(config.tokens[i], true);
        }
    }

    /**
     * @dev Tells whether a token is allowed or not
     * @param token Address of the token being queried
     */
    function isTokenAllowed(address token) public view override returns (bool) {
        bool containsToken = _tokens.contains(token);
        return tokensAcceptanceType == TokensAcceptanceType.AllowList ? containsToken : !containsToken;
    }

    /**
     * @dev Sets the tokens acceptance type of the task
     * @param newTokensAcceptanceType New token acceptance type to be set
     */
    function setTokensAcceptanceType(TokensAcceptanceType newTokensAcceptanceType)
        external
        override
        authP(authParams(uint8(newTokensAcceptanceType)))
    {
        _setTokensAcceptanceType(newTokensAcceptanceType);
    }

    /**
     * @dev Updates the list of tokens of the tokens acceptance list
     * @param tokens List of tokens to be updated from the acceptance list
     * @param added Whether each of the given tokens should be added or removed from the list
     */
    function setTokensAcceptanceList(address[] memory tokens, bool[] memory added) external override auth {
        if (tokens.length != added.length) revert TaskAcceptanceInputLengthMismatch();
        for (uint256 i = 0; i < tokens.length; i++) {
            _setTokenAcceptanceList(tokens[i], added[i]);
        }
    }

    /**
     * @dev Before token indexed task hook
     */
    function _beforeTokenIndexedTask(address token, uint256) internal virtual {
        if (!isTokenAllowed(token)) revert TaskTokenNotAllowed(token);
    }

    /**
     * @dev After token indexed task hook
     */
    function _afterTokenIndexedTask(address token, uint256) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Sets the tokens acceptance type of the task
     * @param newTokensAcceptanceType New token acceptance type to be set
     */
    function _setTokensAcceptanceType(TokensAcceptanceType newTokensAcceptanceType) internal {
        tokensAcceptanceType = newTokensAcceptanceType;
        emit TokensAcceptanceTypeSet(newTokensAcceptanceType);
    }

    /**
     * @dev Updates a token from the tokens acceptance list
     * @param token Token to be updated from the acceptance list
     * @param added Whether the token should be added or removed from the list
     */
    function _setTokenAcceptanceList(address token, bool added) internal {
        if (token == address(0)) revert TaskAcceptanceTokenZero();
        added ? _tokens.add(token) : _tokens.remove(token);
        emit TokensAcceptanceListSet(token, added);
    }
}