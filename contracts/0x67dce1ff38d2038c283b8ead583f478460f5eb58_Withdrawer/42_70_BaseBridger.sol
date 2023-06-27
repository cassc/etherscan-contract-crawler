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

pragma solidity ^0.8.0;

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v2-helpers/contracts/utils/EnumerableMap.sol';

import './interfaces/IBaseBridger.sol';
import '../Action.sol';

/**
 * @title Bridger action
 * @dev Action that offers the basic components for more detailed bridge actions.
 */
abstract contract BaseBridger is IBaseBridger, Action {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;

    // Ethereum mainnet chain ID
    uint256 internal constant MAINNET_CHAIN_ID = 1;

    // Default destination chain
    uint256 private _defaultDestinationChain;

    // Destination chain per token address
    EnumerableMap.AddressToUintMap private _customDestinationChains;

    /**
     * @dev Custom destination chain config
     */
    struct CustomDestinationChain {
        address token;
        uint256 destinationChain;
    }

    /**
     * @dev Bridger action config
     */
    struct BridgerConfig {
        uint256 destinationChain;
        CustomDestinationChain[] customDestinationChains;
        ActionConfig actionConfig;
    }

    /**
     * @dev Creates a swapper action
     */
    constructor(BridgerConfig memory config) Action(config.actionConfig) {
        _setDefaultDestinationChain(config.destinationChain);

        for (uint256 i = 0; i < config.customDestinationChains.length; i++) {
            CustomDestinationChain memory customConfig = config.customDestinationChains[i];
            _setCustomDestinationChain(customConfig.token, customConfig.destinationChain);
        }
    }

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultDestinationChain() public view override returns (uint256) {
        return _defaultDestinationChain;
    }

    /**
     * @dev Tells the destination chain defined for a specific token
     */
    function getCustomDestinationChain(address token) public view override returns (bool, uint256) {
        return _customDestinationChains.tryGet(token);
    }

    /**
     * @dev Tells the list of custom destination chains set
     */
    function getCustomDestinationChains()
        public
        view
        override
        returns (address[] memory tokens, uint256[] memory destinationChains)
    {
        tokens = _customDestinationChains.keys();
        destinationChains = _customDestinationChains.values();
    }

    /**
     * @dev Sets the default destination chain
     */
    function setDefaultDestinationChain(uint256 destinationChain) external override auth {
        _setDefaultDestinationChain(destinationChain);
    }

    /**
     * @dev Sets a list of custom token outs
     */
    function setCustomDestinationChains(address[] memory tokens, uint256[] memory destinationChains)
        external
        override
        auth
    {
        _setCustomDestinationChains(tokens, destinationChains);
    }

    /**
     * @dev Tells the destination chain that should be used for a token
     */
    function _getApplicableDestinationChain(address token) internal view returns (uint256) {
        (bool exists, uint256 destinationChain) = getCustomDestinationChain(token);
        return exists ? destinationChain : getDefaultDestinationChain();
    }

    /**
     * @dev Reverts if the token or the amount are zero
     */
    function _beforeAction(address token, uint256 amount) internal virtual override {
        super._beforeAction(token, amount);
        require(token != address(0), 'ACTION_TOKEN_ZERO');
        require(amount > 0, 'ACTION_AMOUNT_ZERO');
        require(_getApplicableDestinationChain(token) != 0, 'ACTION_DESTINATION_CHAIN_NOT_SET');
    }

    /**
     * @dev Sets the default destination chain
     * @param destinationChain Default destination chain to be set
     */
    function _setDefaultDestinationChain(uint256 destinationChain) internal {
        require(destinationChain != block.chainid, 'ACTION_BRIDGE_CURRENT_CHAIN_ID');
        _defaultDestinationChain = destinationChain;
        emit DefaultDestinationChainSet(destinationChain);
    }

    /**
     * @dev Sets a list of custom destination chains for a set of tokens
     * @param tokens List of addresses of the tokens to set the custom destination chain for
     * @param destinationChains List of destination chains to be set
     */
    function _setCustomDestinationChains(address[] memory tokens, uint256[] memory destinationChains) internal {
        require(tokens.length == destinationChains.length, 'ACTION_CHAIN_IDS_BAD_INPUT_LEN');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setCustomDestinationChain(tokens[i], destinationChains[i]);
        }
    }

    /**
     * @dev Sets a custom destination chain for a token
     * @param token Address of the token to set the custom destination chain for
     * @param destinationChain Destination chain to be set
     */
    function _setCustomDestinationChain(address token, uint256 destinationChain) internal {
        require(destinationChain != block.chainid, 'ACTION_BRIDGE_CURRENT_CHAIN_ID');

        destinationChain == 0
            ? _customDestinationChains.remove(token)
            : _customDestinationChains.set(token, destinationChain);

        emit CustomDestinationChainSet(token, destinationChain);
    }
}