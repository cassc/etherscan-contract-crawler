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

import '@mimic-fi/v2-bridge-connector/contracts/IBridgeConnector.sol';
import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/utils/EnumerableMap.sol';

import './BaseBridger.sol';
import './interfaces/IHopBridger.sol';

contract HopBridger is IHopBridger, BaseBridger {
    using FixedPoint for uint256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 32e3;

    // Relayer address
    address private _relayer;

    // Maximum deadline in seconds
    uint256 private _maxDeadline;

    // Default max fee pct
    uint256 private _defaultMaxFeePct;

    // Default maximum slippage in fixed point
    uint256 private _defaultMaxSlippage;

    // Maximum slippage per token address
    EnumerableMap.AddressToUintMap private _customMaxSlippages;

    // Max fee percentage per token
    EnumerableMap.AddressToUintMap private _customMaxFeePcts;

    // List of Hop entrypoints per token
    EnumerableMap.AddressToAddressMap private _tokenHopEntrypoints;

    /**
     * @dev Custom max fee percentage config
     */
    struct CustomMaxFeePct {
        address token;
        uint256 maxFeePct;
    }

    /**
     * @dev Custom max slippage config
     */
    struct CustomMaxSlippage {
        address token;
        uint256 maxSlippage;
    }

    /**
     * @dev Token Hop entrypoint config
     */
    struct TokenHopEntrypoint {
        address token;
        address entrypoint;
    }

    /**
     * @dev Swapper action config
     */
    struct HopBridgerConfig {
        address relayer;
        uint256 maxFeePct;
        uint256 maxSlippage;
        uint256 maxDeadline;
        CustomMaxFeePct[] customMaxFeePcts;
        CustomMaxSlippage[] customMaxSlippages;
        TokenHopEntrypoint[] tokenHopEntrypoints;
        BridgerConfig bridgerConfig;
    }

    /**
     * @dev Creates a Hop bridger action
     */
    constructor(HopBridgerConfig memory config) BaseBridger(config.bridgerConfig) {
        _setRelayer(config.relayer);
        _setMaxDeadline(config.maxDeadline);
        _setDefaultMaxFeePct(config.maxFeePct);
        _setDefaultMaxSlippage(config.maxSlippage);

        for (uint256 i = 0; i < config.customMaxSlippages.length; i++) {
            _setCustomMaxSlippage(config.customMaxSlippages[i].token, config.customMaxSlippages[i].maxSlippage);
        }

        for (uint256 i = 0; i < config.customMaxFeePcts.length; i++) {
            CustomMaxFeePct memory customMaxFeePct = config.customMaxFeePcts[i];
            _setCustomMaxFeePct(customMaxFeePct.token, customMaxFeePct.maxFeePct);
        }

        for (uint256 i = 0; i < config.tokenHopEntrypoints.length; i++) {
            TokenHopEntrypoint memory tokenHopEntrypoint = config.tokenHopEntrypoints[i];
            _setTokenHopEntrypoint(tokenHopEntrypoint.token, tokenHopEntrypoint.entrypoint);
        }
    }

    /**
     * @dev Tells the relayer address, only used when bridging from L1 to L2
     */
    function getRelayer() public view override returns (address) {
        return _relayer;
    }

    /**
     * @dev Tells the max deadline
     */
    function getMaxDeadline() public view override returns (uint256) {
        return _maxDeadline;
    }

    /**
     * @dev Tells the default max fee pct
     */
    function getDefaultMaxFeePct() public view override returns (uint256) {
        return _defaultMaxFeePct;
    }

    /**
     * @dev Tells the default token threshold
     */
    function getDefaultMaxSlippage() public view override returns (uint256) {
        return _defaultMaxSlippage;
    }

    /**
     * @dev Tells the max fee percentage defined for a specific token
     */
    function getCustomMaxFeePct(address token) public view override returns (bool, uint256) {
        return _customMaxFeePcts.tryGet(token);
    }

    /**
     * @dev Tells the list of custom max fee percentages set
     */
    function getCustomMaxFeePcts()
        external
        view
        override
        returns (address[] memory tokens, uint256[] memory maxFeePcts)
    {
        tokens = _customMaxFeePcts.keys();
        maxFeePcts = _customMaxFeePcts.values();
    }

    /**
     * @dev Tells the max slippage defined for a specific token
     */
    function getCustomMaxSlippage(address token) public view override returns (bool, uint256) {
        return _customMaxSlippages.tryGet(token);
    }

    /**
     * @dev Tells the list of custom max slippages set
     */
    function getCustomMaxSlippages()
        external
        view
        override
        returns (address[] memory tokens, uint256[] memory maxSlippages)
    {
        tokens = _customMaxSlippages.keys();
        maxSlippages = _customMaxSlippages.values();
    }

    /**
     * @dev Tells Hop entrypoint set for a token
     */
    function getTokenHopEntrypoint(address token) public view override returns (bool exists, address entrypoint) {
        return _tokenHopEntrypoints.tryGet(token);
    }

    /**
     * @dev Tells the list of Hop entrypoints set for each token
     */
    function getTokenHopEntrypoints()
        external
        view
        override
        returns (address[] memory tokens, address[] memory entrypoints)
    {
        tokens = _tokenHopEntrypoints.keys();
        entrypoints = _tokenHopEntrypoints.values();
    }

    /**
     * @dev Sets the relayer, only used when bridging from L1 to L2
     * @param relayer New relayer address to be set
     */
    function setRelayer(address relayer) external override auth {
        _setRelayer(relayer);
    }

    /**
     * @dev Sets the max deadline
     * @param maxDeadline New max deadline to be set
     */
    function setMaxDeadline(uint256 maxDeadline) external override auth {
        _setMaxDeadline(maxDeadline);
    }

    /**
     * @dev Sets the default max fee percentage
     * @param maxFeePct New default max fee percentage to be set
     */
    function setDefaultMaxFeePct(uint256 maxFeePct) external override auth {
        _setDefaultMaxFeePct(maxFeePct);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage New default max slippage to be set
     */
    function setDefaultMaxSlippage(uint256 maxSlippage) external override auth {
        _setDefaultMaxSlippage(maxSlippage);
    }

    /**
     * @dev Sets a list of custom max fee percentages
     * @param tokens List of token addresses to set a max fee percentage for
     * @param maxFeePcts List of max fee percentages to be set for each token
     */
    function setCustomMaxFeePcts(address[] memory tokens, uint256[] memory maxFeePcts) external override auth {
        _setCustomMaxFeePcts(tokens, maxFeePcts);
    }

    /**
     * @dev Sets a list of custom max slippages
     * @param tokens List of token addresses to set a max slippage for
     * @param maxSlippages List of max slippages to be set for each token
     */
    function setCustomMaxSlippages(address[] memory tokens, uint256[] memory maxSlippages) external override auth {
        _setCustomMaxSlippages(tokens, maxSlippages);
    }

    /**
     * @dev Sets a list of entrypoints for a list of tokens
     * @param tokens List of token addresses to set a Hop entrypoint for
     * @param entrypoints List of Hop entrypoint addresses to be set for each token
     */
    function setTokenHopEntrypoints(address[] memory tokens, address[] memory entrypoints) external override auth {
        _setTokenHopEntrypoints(tokens, entrypoints);
    }

    /**
     * @dev Execution function
     */
    function call(address token, uint256 amount, uint256 slippage, uint256 fee)
        external
        override
        actionCall(token, amount)
    {
        _validateHopEntrypoint(token);
        _validateSlippage(token, slippage);
        _validateFee(token, amount, fee);

        address entrypoint = _tokenHopEntrypoints.get(token);
        uint256 destinationChainId = _getApplicableDestinationChain(token);

        bytes memory data;
        if (block.chainid == MAINNET_CHAIN_ID) {
            data = abi.encode(entrypoint, block.timestamp + getMaxDeadline(), getRelayer(), fee);
        } else {
            data = (destinationChainId == MAINNET_CHAIN_ID)
                ? abi.encode(entrypoint, fee)
                : abi.encode(entrypoint, fee, block.timestamp + getMaxDeadline());
        }

        smartVault.bridge(
            uint8(IBridgeConnector.Source.Hop),
            destinationChainId,
            token,
            amount,
            ISmartVault.BridgeLimit.Slippage,
            slippage,
            address(smartVault),
            data
        );
    }

    /**
     * @dev Tells the max slippage that should be used for a token
     */
    function _getApplicableMaxSlippage(address token) internal view returns (uint256) {
        (bool exists, uint256 maxSlippage) = getCustomMaxSlippage(token);
        return exists ? maxSlippage : getDefaultMaxSlippage();
    }

    /**
     * @dev Tells the max fee percentage that should be used for a token
     */
    function _getApplicableMaxFeePct(address token) internal view returns (uint256) {
        (bool exists, uint256 maxFeePct) = getCustomMaxFeePct(token);
        return exists ? maxFeePct : getDefaultMaxFeePct();
    }

    /**
     * @dev Tells if a token has a Hop entrypoint set
     */
    function _isHopEntrypointValid(address token) internal view returns (bool) {
        return _tokenHopEntrypoints.contains(token);
    }

    /**
     * @dev Reverts if there is no Hop entrypoint set for a given token
     */
    function _validateHopEntrypoint(address token) internal view {
        require(_isHopEntrypointValid(token), 'ACTION_MISSING_HOP_ENTRYPOINT');
    }

    /**
     * @dev Tells if a slippage is valid based on the max slippage configured for a token
     */
    function _isSlippageValid(address token, uint256 slippage) internal view returns (bool) {
        return slippage <= _getApplicableMaxSlippage(token);
    }

    /**
     * @dev Reverts if the requested slippage is above the max slippage configured for a token
     */
    function _validateSlippage(address token, uint256 slippage) internal view {
        require(_isSlippageValid(token, slippage), 'ACTION_SLIPPAGE_TOO_HIGH');
    }

    /**
     * @dev Tells if the requested fee is valid based on the max fee percentage configured for a token
     */
    function _isFeeValid(address token, uint256 amount, uint256 fee) internal view returns (bool) {
        return fee.divUp(amount) <= _getApplicableMaxFeePct(token);
    }

    /**
     * @dev Reverts if the requested fee is above the max fee percentage configured for a token
     */
    function _validateFee(address token, uint256 amount, uint256 fee) internal view {
        require(_isFeeValid(token, amount, fee), 'ACTION_FEE_TOO_HIGH');
    }

    /**
     * @dev Sets the relayer address, only used when bridging from L1 to L2
     */
    function _setRelayer(address relayer) internal {
        _relayer = relayer;
        emit RelayerSet(relayer);
    }

    /**
     * @dev Sets the max deadline
     */
    function _setMaxDeadline(uint256 maxDeadline) internal {
        require(maxDeadline > 0, 'ACTION_MAX_DEADLINE_ZERO');
        _maxDeadline = maxDeadline;
        emit MaxDeadlineSet(maxDeadline);
    }

    /**
     * @dev Sets the default max slippage
     * @param maxSlippage Default max slippage to be set
     */
    function _setDefaultMaxSlippage(uint256 maxSlippage) internal {
        require(maxSlippage <= FixedPoint.ONE, 'ACTION_SLIPPAGE_ABOVE_ONE');
        _defaultMaxSlippage = maxSlippage;
        emit DefaultMaxSlippageSet(maxSlippage);
    }

    /**
     * @dev Sets the default max fee percentage
     * @param maxFeePct Default max fee percentage to be set
     */
    function _setDefaultMaxFeePct(uint256 maxFeePct) internal {
        _defaultMaxFeePct = maxFeePct;
        emit DefaultMaxFeePctSet(maxFeePct);
    }

    /**
     * @dev Sets a list of Hop entrypoints for a list of tokens
     * @param tokens List of token addresses to be set
     * @param entrypoints List of Hop entrypoint addresses to be set for each token
     */
    function _setTokenHopEntrypoints(address[] memory tokens, address[] memory entrypoints) internal {
        require(tokens.length == entrypoints.length, 'ACTION_HOP_ENTRYPOINTS_BAD_INPUT');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setTokenHopEntrypoint(tokens[i], entrypoints[i]);
        }
    }

    /**
     * @dev Set a Hop entrypoint for a token
     * @param token Address of the token to set a Hop entrypoint for
     * @param entrypoint Hop entrypoint to be set
     */
    function _setTokenHopEntrypoint(address token, address entrypoint) internal {
        require(token != address(0), 'ACTION_HOP_TOKEN_ZERO');
        bool isZero = entrypoint == address(0);
        isZero ? _tokenHopEntrypoints.remove(token) : _tokenHopEntrypoints.set(token, entrypoint);
        emit TokenHopEntrypointSet(token, entrypoint);
    }

    /**
     * @dev Sets a list of custom max slippages for a list of tokens
     * @param tokens List of addresses of the tokens to set a custom max slippage for
     * @param maxSlippages List of max slippages to be set for each token
     */
    function _setCustomMaxSlippages(address[] memory tokens, uint256[] memory maxSlippages) internal {
        require(tokens.length == maxSlippages.length, 'ACTION_SLIPPAGES_BAD_INPUT_LEN');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setCustomMaxSlippage(tokens[i], maxSlippages[i]);
        }
    }

    /**
     * @dev Sets a custom max slippage for a token
     * @param token Address of the token to set the custom max slippage for
     * @param maxSlippage Max slippage to be set for the given token
     */
    function _setCustomMaxSlippage(address token, uint256 maxSlippage) internal {
        require(maxSlippage <= FixedPoint.ONE, 'ACTION_SLIPPAGE_ABOVE_ONE');
        maxSlippage == 0 ? _customMaxSlippages.remove(token) : _customMaxSlippages.set(token, maxSlippage);
        emit CustomMaxSlippageSet(token, maxSlippage);
    }

    /**
     * @dev Sets a list of custom max fee percentages for a list of tokens
     * @param tokens List of addresses of the tokens to set a max fee percentage for
     * @param maxFeePcts List of max fee percentages to be set per token
     */
    function _setCustomMaxFeePcts(address[] memory tokens, uint256[] memory maxFeePcts) internal {
        require(tokens.length == maxFeePcts.length, 'ACTION_MAX_FEE_PCTS_BAD_INPUT');
        for (uint256 i = 0; i < tokens.length; i++) {
            _setCustomMaxFeePct(tokens[i], maxFeePcts[i]);
        }
    }

    /**
     * @dev Sets a custom max fee percentage for a token
     * @param token Address of the token to set a custom max fee percentage for
     * @param maxFeePct Max fee percentage to be set for the given token
     */
    function _setCustomMaxFeePct(address token, uint256 maxFeePct) internal {
        maxFeePct == 0 ? _customMaxFeePcts.remove(token) : _customMaxFeePcts.set(token, maxFeePct);
        emit CustomMaxFeePctSet(token, maxFeePct);
    }
}