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

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';

import './BaseAction.sol';
import './interfaces/IRelayedAction.sol';

/**
 * @dev Relayers config for actions. It allows redeeming consumed gas based on an allow-list of relayers and cost limit.
 */
abstract contract RelayedAction is IRelayedAction, BaseAction {
    using FixedPoint for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Base gas amount charged to cover default amounts
    // solhint-disable-next-line func-name-mixedcase
    function BASE_GAS() external view virtual returns (uint256);

    // Note to be used to mark tx cost payments
    bytes private constant REDEEM_GAS_NOTE = bytes('RELAYER');

    // Variable used to allow a better developer experience to reimburse tx gas cost
    // solhint-disable-next-line var-name-mixedcase
    uint256 private __initialGas__;

    // Gas price limit expressed in the native token
    uint256 private _gasPriceLimit;

    // Priority fee limit expressed in the native token
    uint256 private _priorityFeeLimit;

    // Total transaction cost limit expressed in the native token
    uint256 private _txCostLimit;

    // Token that will be used to redeem gas costs
    address private _gasToken;

    // Allows relaying transactions even if there is not enough balance in the Smart Vault to pay for the tx gas cost
    bool private _permissiveMode;

    // List of allowed relayers
    EnumerableSet.AddressSet private _relayers;

    /**
     * @dev Relayed action config. Only used in the constructor.
     * @param gasPriceLimit Gas price limit expressed in the native token
     * @param priorityFeeLimit Priority fee limit expressed in the native token
     * @param txCostLimit Transaction cost limit to be set
     * @param gasToken Token that will be used to redeem gas costs
     * @param permissiveMode Whether the permissive mode is active
     * @param relayers List of relayers to be added to the allow-list
     */
    struct RelayConfig {
        uint256 gasPriceLimit;
        uint256 priorityFeeLimit;
        uint256 txCostLimit;
        address gasToken;
        bool permissiveMode;
        address[] relayers;
    }

    /**
     * @dev Creates a new relayers config
     */
    constructor(RelayConfig memory config) {
        _setRelayGasLimit(config.gasPriceLimit, config.priorityFeeLimit);
        _setRelayTxCostLimit(config.txCostLimit);
        _setRelayGasToken(config.gasToken);
        _setRelayPermissiveMode(config.permissiveMode);
        _addRelayers(config.relayers);
    }

    /**
     * @dev Tells the action gas limits
     */
    function getRelayGasLimits() public view override returns (uint256 gasPriceLimit, uint256 priorityFeeLimit) {
        return (_gasPriceLimit, _priorityFeeLimit);
    }

    /**
     * @dev Tells the transaction cost limit
     */
    function getRelayTxCostLimit() public view override returns (uint256) {
        return _txCostLimit;
    }

    /**
     * @dev Tells the relayed paying gas token
     */
    function getRelayGasToken() public view override returns (address) {
        return _gasToken;
    }

    /**
     * @dev Tells whether the permissive relayed mode is active
     */
    function isRelayPermissiveModeActive() public view override returns (bool) {
        return _permissiveMode;
    }

    /**
     * @dev Tells if a relayer is allowed or not
     * @param relayer Address of the relayer to be checked
     */
    function isRelayer(address relayer) public view override returns (bool) {
        return _relayers.contains(relayer);
    }

    /**
     * @dev Tells the list of allowed relayers
     */
    function getRelayers() public view override returns (address[] memory) {
        return _relayers.values();
    }

    /**
     * @dev Sets the relay gas limits
     * @param gasPriceLimit New relay gas price limit to be set
     * @param priorityFeeLimit New relay priority fee limit to be set
     */
    function setRelayGasLimits(uint256 gasPriceLimit, uint256 priorityFeeLimit) external override auth {
        _setRelayGasLimit(gasPriceLimit, priorityFeeLimit);
    }

    /**
     * @dev Sets the relay transaction cost limit
     * @param txCostLimit New relay transaction cost limit to be set
     */
    function setRelayTxCostLimit(uint256 txCostLimit) external override auth {
        _setRelayTxCostLimit(txCostLimit);
    }

    /**
     * @dev Sets the relay gas token
     * @param token Address of the token to be set as the relay gas token
     */
    function setRelayGasToken(address token) external override auth {
        _setRelayGasToken(token);
    }

    /**
     * @dev Sets the relay permissive mode
     * @param active Whether the relay permissive mode should be active or not
     */
    function setRelayPermissiveMode(bool active) external override auth {
        _setRelayPermissiveMode(active);
    }

    /**
     * @dev Updates the list of allowed relayers
     * @param relayersToAdd List of relayers to be added to the allow-list
     * @param relayersToRemove List of relayers to be removed from the allow-list
     * @notice The list of relayers to be added will be processed first to make sure no undesired relayers are allowed
     */
    function setRelayers(address[] memory relayersToAdd, address[] memory relayersToRemove) external override auth {
        _addRelayers(relayersToAdd);
        _removeRelayers(relayersToRemove);
    }

    /**
     * @dev Reverts if the tx fee does not comply with the configured gas limits
     */
    function _validateGasLimit() internal view {
        require(_areGasLimitsValid(), 'ACTION_GAS_LIMITS_EXCEEDED');
    }

    /**
     * @dev Tells if the tx fee data is compliant with the configured gas limits
     */
    function _areGasLimitsValid() internal view returns (bool) {
        return _isGasPriceValid() && _isPriorityFeeValid();
    }

    /**
     * @dev Tells if the tx gas price is compliant with the configured gas price limit
     */
    function _isGasPriceValid() internal view returns (bool) {
        if (_gasPriceLimit == 0) return true;
        return tx.gasprice <= _gasPriceLimit;
    }

    /**
     * @dev Tells if the tx priority fee is compliant with the configured priority fee limit
     */
    function _isPriorityFeeValid() internal view returns (bool) {
        if (_priorityFeeLimit == 0) return true;
        return tx.gasprice - block.basefee <= _priorityFeeLimit;
    }

    /**
     * @dev Reverts if the tx cost does not comply with the configured limit
     */
    function _validateTxCostLimit(uint256 totalCost) internal view {
        require(_isTxCostValid(totalCost), 'ACTION_TX_COST_LIMIT_EXCEEDED');
    }

    /**
     * @dev Tells if a given transaction cost is compliant with the configured transaction cost limit
     * @param totalCost Transaction cost in native token to be checked
     */
    function _isTxCostValid(uint256 totalCost) internal view returns (bool) {
        return _txCostLimit == 0 || totalCost <= _txCostLimit;
    }

    /**
     * @dev Initializes relayed txs, only when the sender is marked as a relayer
     */
    function _beforeAction(address, uint256) internal virtual override {
        if (!isRelayer(msg.sender)) return;
        __initialGas__ = gasleft();
        _validateGasLimit();
    }

    /**
     * @dev Reimburses the tx cost, only when the sender is marked as a relayer
     */
    function _afterAction(address, uint256) internal virtual override {
        if (!isRelayer(msg.sender)) return;
        require(__initialGas__ > 0, 'ACTION_RELAY_NOT_INITIALIZED');

        uint256 totalGas = RelayedAction(this).BASE_GAS() + __initialGas__ - gasleft();
        uint256 totalCostNative = totalGas * tx.gasprice;
        _validateTxCostLimit(totalCostNative);

        uint256 price = _isWrappedOrNative(_gasToken) ? FixedPoint.ONE : _getPrice(_wrappedNativeToken(), _gasToken);
        uint256 totalCostGasToken = totalCostNative.mulDown(price);
        if (getSmartVaultBalance(_gasToken) >= totalCostGasToken || !_permissiveMode) {
            smartVault.withdraw(_gasToken, totalCostGasToken, smartVault.feeCollector(), REDEEM_GAS_NOTE);
        }

        delete __initialGas__;
    }

    /**
     * @dev Sets the relay gas limits
     * @param gasPriceLimit New relay gas price limit to be set
     * @param priorityFeeLimit New relay priority fee limit to be set
     */
    function _setRelayGasLimit(uint256 gasPriceLimit, uint256 priorityFeeLimit) internal {
        _gasPriceLimit = gasPriceLimit;
        _priorityFeeLimit = priorityFeeLimit;
        emit RelayGasLimitsSet(gasPriceLimit, priorityFeeLimit);
    }

    /**
     * @dev Sets the relay transaction cost limit
     * @param txCostLimit New relay transaction cost limit to be set
     */
    function _setRelayTxCostLimit(uint256 txCostLimit) internal {
        _txCostLimit = txCostLimit;
        emit RelayTxCostLimitSet(txCostLimit);
    }

    /**
     * @dev Sets the relay gas token
     * @param token Address of the token to be set as the relay gas token
     */
    function _setRelayGasToken(address token) internal {
        _gasToken = token;
        emit RelayGasTokenSet(token);
    }

    /**
     * @dev Sets the relay permissive mode
     * @param active Whether the relay permissive mode should be active or not
     */
    function _setRelayPermissiveMode(bool active) internal {
        _permissiveMode = active;
        emit RelayPermissiveModeSet(active);
    }

    /**
     * @dev Adds a list of addresses to the relayers allow-list
     * @param relayers List of addresses to be added to the allow-list
     */
    function _addRelayers(address[] memory relayers) internal {
        for (uint256 i = 0; i < relayers.length; i++) {
            address relayer = relayers[i];
            require(relayer != address(0), 'RELAYER_ADDRESS_ZERO');
            if (_relayers.add(relayer)) emit RelayerAllowed(relayer);
        }
    }

    /**
     * @dev Removes a list of addresses from the relayers allow-list
     * @param relayers List of addresses to be removed from the allow-list
     */
    function _removeRelayers(address[] memory relayers) internal {
        for (uint256 i = 0; i < relayers.length; i++) {
            address relayer = relayers[i];
            if (_relayers.remove(relayer)) emit RelayerDisallowed(relayer);
        }
    }
}