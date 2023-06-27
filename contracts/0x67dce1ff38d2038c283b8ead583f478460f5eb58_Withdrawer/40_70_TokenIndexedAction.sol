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

import '@mimic-fi/v2-helpers/contracts/auth/Authorizer.sol';

import './BaseAction.sol';
import './interfaces/ITokenIndexedAction.sol';

/**
 * @dev Token indexed actions. It defines a token acceptance list to tell which are the tokens supported by the
 * action. Tokens acceptance can be configured either as an allow list or as a deny list.
 */
abstract contract TokenIndexedAction is ITokenIndexedAction, BaseAction {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Acceptance list type
    TokensAcceptanceType private _acceptanceType;

    // Enumerable set of tokens included in the acceptance list
    EnumerableSet.AddressSet private _tokens;

    // Enumerable set of sources where tokens balances should be checked. Only used for deny lists.
    EnumerableSet.AddressSet private _sources;

    /**
     * @dev Token index config. Only used in the constructor.
     * @param tokens List of token addresses to be set for the acceptance list
     * @param sources List of sources where tokens balances should be checked. Only used for deny lists.
     * @param acceptanceType Token acceptance type to be set
     */
    struct TokenIndexConfig {
        address[] tokens;
        address[] sources;
        TokensAcceptanceType acceptanceType;
    }

    /**
     * @dev Creates a new token indexed action
     */
    constructor(TokenIndexConfig memory config) {
        _addTokens(config.tokens);
        _addSources(config.sources);
        _setTokensAcceptanceType(config.acceptanceType);
    }

    /**
     * @dev Tells the list of tokens included in an acceptance config
     */
    function getTokensAcceptanceType() public view override returns (TokensAcceptanceType) {
        return _acceptanceType;
    }

    /**
     * @dev Tells if the requested token is compliant with the tokens acceptance list
     * @param token Address of the token to be checked
     */
    function isTokenAllowed(address token) public view override returns (bool) {
        return _acceptanceType == TokensAcceptanceType.AllowList ? _tokens.contains(token) : !_tokens.contains(token);
    }

    /**
     * @dev Tells the list of tokens included in an acceptance config
     */
    function getTokensAcceptanceList() public view override returns (address[] memory) {
        return _tokens.values();
    }

    /**
     * @dev Tells the list of sources included in an acceptance config
     */
    function getTokensIndexSources() public view override returns (address[] memory) {
        return _sources.values();
    }

    /**
     * @dev Sets the tokens acceptance type of the action
     * @param acceptanceType New token acceptance type to be set
     */
    function setTokensAcceptanceType(TokensAcceptanceType acceptanceType) external override auth {
        _setTokensAcceptanceType(acceptanceType);
    }

    /**
     * @dev Updates the list of tokens of the tokens acceptance list
     * @param toAdd List of tokens to be added to the acceptance list
     * @param toRemove List of tokens to be removed from the acceptance list
     * @notice The list of tokens to be added will be processed first
     */
    function setTokensAcceptanceList(address[] memory toAdd, address[] memory toRemove) external override auth {
        _addTokens(toAdd);
        _removeTokens(toRemove);
    }

    /**
     * @dev Updates the list of sources of the tokens index config
     * @param toAdd List of sources to be added to the acceptance list
     * @param toRemove List of sources to be removed from the acceptance list
     * @notice The list of sources to be added will be processed first
     */
    function setTokensIndexSources(address[] memory toAdd, address[] memory toRemove) external override auth {
        _addSources(toAdd);
        _removeSources(toRemove);
    }

    /**
     * @dev Reverts if the requested token does not comply with the tokens acceptance list
     */
    function _beforeAction(address token, uint256) internal virtual override {
        require(isTokenAllowed(token), 'ACTION_TOKEN_NOT_ALLOWED');
    }

    /**
     * @dev Sets the tokens acceptance type of the action
     * @param acceptanceType New token acceptance type to be set
     */
    function _setTokensAcceptanceType(TokensAcceptanceType acceptanceType) private {
        _acceptanceType = acceptanceType;
        emit TokensAcceptanceTypeSet(acceptanceType);
    }

    /**
     * @dev Adds a list of addresses to the tokens acceptance list
     * @param tokens List of addresses to be added to the acceptance list
     */
    function _addTokens(address[] memory tokens) private {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(token != address(0), 'TOKEN_ADDRESS_ZERO');
            if (_tokens.add(token)) emit TokensAcceptanceAdded(token);
        }
    }

    /**
     * @dev Removes a list of addresses from the tokens acceptance list
     * @param tokens List of addresses to be removed from the acceptance list
     */
    function _removeTokens(address[] memory tokens) private {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (_tokens.remove(token)) emit TokensAcceptanceRemoved(token);
        }
    }

    /**
     * @dev Adds a list of addresses to the sources list
     * @param sources List of addresses to be added to the source list
     */
    function _addSources(address[] memory sources) private {
        for (uint256 i = 0; i < sources.length; i++) {
            address source = sources[i];
            require(source != address(0), 'SOURCE_ADDRESS_ZERO');
            if (_sources.add(source)) emit TokenIndexSourceAdded(source);
        }
    }

    /**
     * @dev Removes a list of addresses from the sources allow-list
     * @param sources List of addresses to be removed from the allow-list
     */
    function _removeSources(address[] memory sources) private {
        for (uint256 i = 0; i < sources.length; i++) {
            address source = sources[i];
            if (_sources.remove(source)) emit TokenIndexSourceRemoved(source);
        }
    }
}