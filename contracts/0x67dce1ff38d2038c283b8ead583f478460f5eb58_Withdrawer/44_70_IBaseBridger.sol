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

import '../../IAction.sol';

/**
 * @dev Base bridger action interface
 */
interface IBaseBridger is IAction {
    /**
     * @dev Emitted every time the default destination chain is set
     */
    event DefaultDestinationChainSet(uint256 indexed defaultDestinationChain);

    /**
     * @dev Emitted every time a custom destination chain is set for a token
     */
    event CustomDestinationChainSet(address indexed token, uint256 indexed defaultDestinationChain);

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultDestinationChain() external view returns (uint256);

    /**
     * @dev Tells the destination chain defined for a specific token
     */
    function getCustomDestinationChain(address token) external view returns (bool exists, uint256 chainId);

    /**
     * @dev Tells the list of custom destination chains set
     */
    function getCustomDestinationChains() external view returns (address[] memory tokens, uint256[] memory chainId);

    /**
     * @dev Sets the default destination chain
     */
    function setDefaultDestinationChain(uint256 destinationChain) external;

    /**
     * @dev Sets a list of custom token outs
     */
    function setCustomDestinationChains(address[] memory tokens, uint256[] memory destinationChains) external;
}