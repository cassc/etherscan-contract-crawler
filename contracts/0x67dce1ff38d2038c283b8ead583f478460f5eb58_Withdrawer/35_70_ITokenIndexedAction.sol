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

pragma solidity >=0.8.0;

import './IBaseAction.sol';

/**
 * @dev Token indexed action interface
 */
interface ITokenIndexedAction is IBaseAction {
    /**
     * @dev Acceptance list types: either deny-list to express "all except" or allow-list to express "only"
     */
    enum TokensAcceptanceType {
        DenyList,
        AllowList
    }

    /**
     * @dev Emitted every time a tokens acceptance type is set
     */
    event TokensAcceptanceTypeSet(TokensAcceptanceType acceptanceType);

    /**
     * @dev Emitted every time a token is added to the acceptance list
     */
    event TokensAcceptanceAdded(address indexed token);

    /**
     * @dev Emitted every time a token is removed from the acceptance list
     */
    event TokensAcceptanceRemoved(address indexed token);

    /**
     * @dev Emitted every time a source is added to the list
     */
    event TokenIndexSourceAdded(address indexed source);

    /**
     * @dev Emitted every time a source is removed from the list
     */
    event TokenIndexSourceRemoved(address indexed source);

    /**
     * @dev Tells the acceptance type of the config
     */
    function getTokensAcceptanceType() external view returns (TokensAcceptanceType);

    /**
     * @dev Tells if a token is included in the acceptance config
     */
    function isTokenAllowed(address token) external view returns (bool);

    /**
     * @dev Tells the list of tokens included in the acceptance config
     */
    function getTokensAcceptanceList() external view returns (address[] memory);

    /**
     * @dev Tells the list of tokens sources accepted by the config
     */
    function getTokensIndexSources() external view returns (address[] memory);

    /**
     * @dev Sets the tokens acceptance type of the action
     * @param acceptanceType New token acceptance type to be set
     */
    function setTokensAcceptanceType(TokensAcceptanceType acceptanceType) external;

    /**
     * @dev Updates the list of tokens of the tokens acceptance list
     * @param tokensToAdd List of tokens to be added to the acceptance list
     * @param tokensToRemove List of tokens to be removed from the acceptance list
     */
    function setTokensAcceptanceList(address[] memory tokensToAdd, address[] memory tokensToRemove) external;

    /**
     * @dev Updates the list of sources of the tokens index config
     * @param toAdd List of sources to be added to the acceptance list
     * @param toRemove List of sources to be removed from the acceptance list
     */
    function setTokensIndexSources(address[] memory toAdd, address[] memory toRemove) external;
}