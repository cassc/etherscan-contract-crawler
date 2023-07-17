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

import '../interfaces/IFantomAsset.sol';

contract FantomBridger is BaseAction, TokenThresholdAction, RelayedAction {
    using FixedPoint for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 60e3;

    EnumerableSet.AddressSet private allowedTokens;

    event AllowedTokenSet(address indexed token, bool allowed);

    struct Config {
        address admin;
        address registry;
        address smartVault;
        address[] allowedTokens;
        address thresholdToken;
        uint256 thresholdAmount;
        address relayer;
        uint256 gasPriceLimit;
    }

    constructor(Config memory config) BaseAction(config.admin, config.registry) {
        require(address(config.smartVault) != address(0), 'SMART_VAULT_ZERO');
        smartVault = ISmartVault(config.smartVault);
        emit SmartVaultSet(config.smartVault);

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

    function setAllowedToken(address token, bool allowed) external auth {
        _setAllowedToken(token, allowed);
    }

    function call(address token, uint256 amount) external auth nonReentrant {
        _initRelayedTx();
        require(amount > 0, 'BRIDGER_AMOUNT_ZERO');
        require(isTokenAllowed(token), 'BRIDGER_TOKEN_NOT_ALLOWED');
        _validateThreshold(token, amount);

        emit Executed();
        uint256 gasRefund = _payRelayedTx(token);
        uint256 bridgeAmount = amount - gasRefund;

        // solhint-disable-next-line func-name-mixedcase
        bytes memory data = abi.encodeWithSelector(IFantomAsset.Swapout.selector, bridgeAmount, address(smartVault));

        // solhint-disable-next-line avoid-low-level-calls
        smartVault.call(token, data, 0, new bytes(0));
    }

    function _setAllowedToken(address token, bool allowed) private {
        require(token != address(0), 'BRIDGER_TOKEN_ZERO');
        if (allowed ? allowedTokens.add(token) : allowedTokens.remove(token)) {
            emit AllowedTokenSet(token, allowed);
        }
    }
}