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

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

contract WormholeBridger is BaseAction, TokenThresholdAction, RelayedAction {
    using FixedPoint for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 60e3;

    // Wormhole bridge connector source ID
    uint8 public constant WORMHOLE_BRIDGE_SOURCE = 3;

    uint256 public maxRelayerFeePct;
    uint256 public destinationChainId;
    EnumerableSet.AddressSet private allowedTokens;

    event AllowedTokenSet(address indexed token, bool allowed);
    event MaxRelayerFeePctSet(uint256 maxFeePct);
    event DestinationChainIdSet(uint256 indexed chainId);

    struct Config {
        address admin;
        address registry;
        address smartVault;
        address[] allowedTokens;
        uint256 maxRelayerFeePct;
        uint256 destinationChainId;
        address thresholdToken;
        uint256 thresholdAmount;
        address relayer;
        uint256 gasPriceLimit;
    }

    constructor(Config memory config) BaseAction(config.admin, config.registry) {
        require(address(config.smartVault) != address(0), 'SMART_VAULT_ZERO');
        smartVault = ISmartVault(config.smartVault);
        emit SmartVaultSet(config.smartVault);

        _setMaxRelayerFeePct(config.maxRelayerFeePct);
        _setDestinationChainId(config.destinationChainId);
        for (uint256 i = 0; i < config.allowedTokens.length; i++) _setAllowedToken(config.allowedTokens[i], true);

        thresholdToken = config.thresholdToken;
        thresholdAmount = config.thresholdAmount;
        emit ThresholdSet(config.thresholdToken, config.thresholdAmount);

        isRelayer[config.relayer] = true;
        emit RelayerSet(config.relayer, true);

        gasPriceLimit = config.gasPriceLimit;
        emit LimitsSet(config.gasPriceLimit, 0);
    }

    function getAllowedTokensLength() external view returns (uint256) {
        return allowedTokens.length();
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return allowedTokens.values();
    }

    function isTokenAllowed(address token) public view returns (bool) {
        return allowedTokens.contains(token);
    }

    function setMaxRelayerFeePct(uint256 newMaxRelayerFeePct) external auth {
        _setMaxRelayerFeePct(newMaxRelayerFeePct);
    }

    function setAllowedToken(address token, bool allowed) external auth {
        _setAllowedToken(token, allowed);
    }

    function setDestinationChainId(uint256 chainId) external auth {
        _setDestinationChainId(chainId);
    }

    function call(address token, uint256 amount, uint256 relayerFee) external auth nonReentrant {
        _initRelayedTx();
        require(amount > 0, 'BRIDGER_AMOUNT_ZERO');
        require(isTokenAllowed(token), 'BRIDGER_TOKEN_NOT_ALLOWED');
        require(destinationChainId != 0, 'BRIDGER_DEST_CHAIN_NOT_SET');
        require(relayerFee.divUp(amount) <= maxRelayerFeePct, 'BRIDGER_RELAYER_FEE_ABOVE_MAX');
        _validateThreshold(token, amount);

        emit Executed();
        uint256 gasRefund = _payRelayedTx(token);
        uint256 amountToBridge = amount - gasRefund;
        uint256 minAmountOut = amountToBridge - relayerFee;

        smartVault.bridge(
            WORMHOLE_BRIDGE_SOURCE,
            destinationChainId,
            token,
            amountToBridge,
            ISmartVault.BridgeLimit.MinAmountOut,
            minAmountOut,
            address(smartVault),
            new bytes(0)
        );
    }

    function _setAllowedToken(address token, bool allowed) private {
        require(token != address(0), 'BRIDGER_TOKEN_ZERO');
        if (allowed ? allowedTokens.add(token) : allowedTokens.remove(token)) {
            emit AllowedTokenSet(token, allowed);
        }
    }

    function _setMaxRelayerFeePct(uint256 newMaxRelayerFeePct) private {
        require(newMaxRelayerFeePct <= FixedPoint.ONE, 'BRIDGER_RELAYER_FEE_PCT_GT_ONE');
        maxRelayerFeePct = newMaxRelayerFeePct;
        emit MaxRelayerFeePctSet(newMaxRelayerFeePct);
    }

    function _setDestinationChainId(uint256 chainId) private {
        require(chainId != block.chainid, 'BRIDGER_SAME_CHAIN_ID');
        destinationChainId = chainId;
        emit DestinationChainIdSet(chainId);
    }
}