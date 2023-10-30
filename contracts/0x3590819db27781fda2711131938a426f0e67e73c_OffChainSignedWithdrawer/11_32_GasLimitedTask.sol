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

import '@mimic-fi/v3-authorizer/contracts/Authorized.sol';
import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-smart-vault/contracts/interfaces/ISmartVault.sol';

import '../interfaces/base/IGasLimitedTask.sol';

/**
 * @dev Gas config for tasks. It allows setting different gas-related configs, specially useful to control relayed txs.
 */
abstract contract GasLimitedTask is IGasLimitedTask, Authorized {
    using FixedPoint for uint256;

    // Variable used to allow a better developer experience to reimburse tx gas cost
    // solhint-disable-next-line var-name-mixedcase
    uint256 private __initialGas__;

    // Gas limits config
    GasLimitConfig internal gasLimits;

    /**
     * @dev Gas limits config
     * @param gasPriceLimit Gas price limit expressed in the native token
     * @param priorityFeeLimit Priority fee limit expressed in the native token
     * @param txCostLimit Transaction cost limit to be set
     * @param txCostLimitPct Transaction cost limit percentage to be set
     */
    struct GasLimitConfig {
        uint256 gasPriceLimit;
        uint256 priorityFeeLimit;
        uint256 txCostLimit;
        uint256 txCostLimitPct;
    }

    /**
     * @dev Initializes the gas limited task. It does call upper contracts initializers.
     * @param config Gas limited task config
     */
    function __GasLimitedTask_init(GasLimitConfig memory config) internal onlyInitializing {
        __GasLimitedTask_init_unchained(config);
    }

    /**
     * @dev Initializes the gas limited task. It does not call upper contracts initializers.
     * @param config Gas limited task config
     */
    function __GasLimitedTask_init_unchained(GasLimitConfig memory config) internal onlyInitializing {
        _setGasLimits(config.gasPriceLimit, config.priorityFeeLimit, config.txCostLimit, config.txCostLimitPct);
    }

    /**
     * @dev Tells the gas limits config
     */
    function getGasLimits()
        external
        view
        returns (uint256 gasPriceLimit, uint256 priorityFeeLimit, uint256 txCostLimit, uint256 txCostLimitPct)
    {
        return (gasLimits.gasPriceLimit, gasLimits.priorityFeeLimit, gasLimits.txCostLimit, gasLimits.txCostLimitPct);
    }

    /**
     * @dev Sets the gas limits config
     * @param newGasPriceLimit New gas price limit to be set
     * @param newPriorityFeeLimit New priority fee limit to be set
     * @param newTxCostLimit New tx cost limit to be set
     * @param newTxCostLimitPct New tx cost percentage limit to be set
     */
    function setGasLimits(
        uint256 newGasPriceLimit,
        uint256 newPriorityFeeLimit,
        uint256 newTxCostLimit,
        uint256 newTxCostLimitPct
    ) external override authP(authParams(newGasPriceLimit, newPriorityFeeLimit, newTxCostLimit, newTxCostLimitPct)) {
        _setGasLimits(newGasPriceLimit, newPriorityFeeLimit, newTxCostLimit, newTxCostLimitPct);
    }

    /**
     * @dev Fetches a base/quote price
     */
    function _getPrice(address base, address quote) internal view virtual returns (uint256);

    /**
     * @dev Initializes gas limited tasks and validates gas price limit
     */
    function _beforeGasLimitedTask(address, uint256) internal virtual {
        __initialGas__ = gasleft();
        GasLimitConfig memory config = gasLimits;
        bool isGasPriceAllowed = config.gasPriceLimit == 0 || tx.gasprice <= config.gasPriceLimit;
        if (!isGasPriceAllowed) revert TaskGasPriceLimitExceeded(tx.gasprice, config.gasPriceLimit);

        uint256 priorityFee = tx.gasprice - block.basefee;
        bool isPriorityFeeAllowed = config.priorityFeeLimit == 0 || priorityFee <= config.priorityFeeLimit;
        if (!isPriorityFeeAllowed) revert TaskPriorityFeeLimitExceeded(priorityFee, config.priorityFeeLimit);
    }

    /**
     * @dev Validates transaction cost limit
     */
    function _afterGasLimitedTask(address token, uint256 amount) internal virtual {
        if (__initialGas__ == 0) revert TaskGasNotInitialized();

        GasLimitConfig memory config = gasLimits;
        uint256 totalGas = __initialGas__ - gasleft();
        uint256 totalCost = totalGas * tx.gasprice;
        bool isTxCostAllowed = config.txCostLimit == 0 || totalCost <= config.txCostLimit;
        if (!isTxCostAllowed) revert TaskTxCostLimitExceeded(totalCost, config.txCostLimit);
        delete __initialGas__;

        if (config.txCostLimitPct > 0 && amount > 0) {
            uint256 price = _getPrice(ISmartVault(this.smartVault()).wrappedNativeToken(), token);
            uint256 totalCostInToken = totalCost.mulUp(price);
            uint256 txCostPct = totalCostInToken.divUp(amount);
            if (txCostPct > config.txCostLimitPct) revert TaskTxCostLimitPctExceeded(txCostPct, config.txCostLimitPct);
        }
    }

    /**
     * @dev Sets the gas limits config
     * @param newGasPriceLimit New gas price limit to be set
     * @param newPriorityFeeLimit New priority fee limit to be set
     * @param newTxCostLimit New tx cost limit to be set
     * @param newTxCostLimitPct New tx cost percentage limit to be set
     */
    function _setGasLimits(
        uint256 newGasPriceLimit,
        uint256 newPriorityFeeLimit,
        uint256 newTxCostLimit,
        uint256 newTxCostLimitPct
    ) internal {
        if (newTxCostLimitPct > FixedPoint.ONE) revert TaskTxCostLimitPctAboveOne();

        gasLimits.gasPriceLimit = newGasPriceLimit;
        gasLimits.priorityFeeLimit = newPriorityFeeLimit;
        gasLimits.txCostLimit = newTxCostLimit;
        gasLimits.txCostLimitPct = newTxCostLimitPct;
        emit GasLimitsSet(newGasPriceLimit, newPriorityFeeLimit, newTxCostLimit, newTxCostLimitPct);
    }
}