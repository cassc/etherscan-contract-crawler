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

import './IBaseTask.sol';

/**
 * @dev Gas limited task interface
 */
interface IGasLimitedTask is IBaseTask {
    /**
     * @dev The tx initial gas cache has not been initialized
     */
    error TaskGasNotInitialized();

    /**
     * @dev The gas price used is greater than the limit
     */
    error TaskGasPriceLimitExceeded(uint256 gasPrice, uint256 gasPriceLimit);

    /**
     * @dev The priority fee used is greater than the priority fee limit
     */
    error TaskPriorityFeeLimitExceeded(uint256 priorityFee, uint256 priorityFeeLimit);

    /**
     * @dev The transaction cost is greater than the transaction cost limit
     */
    error TaskTxCostLimitExceeded(uint256 txCost, uint256 txCostLimit);

    /**
     * @dev The transaction cost percentage is greater than the transaction cost limit percentage
     */
    error TaskTxCostLimitPctExceeded(uint256 txCostPct, uint256 txCostLimitPct);

    /**
     * @dev The new transaction cost limit percentage is greater than one
     */
    error TaskTxCostLimitPctAboveOne();

    /**
     * @dev Emitted every time the gas price limit is set
     */
    event GasPriceLimitSet(uint256 gasPriceLimit);

    /**
     * @dev Emitted every time the priority fee limit is set
     */
    event PriorityFeeLimitSet(uint256 priorityFeeLimit);

    /**
     * @dev Emitted every time the transaction cost limit is set
     */
    event TxCostLimitSet(uint256 txCostLimit);

    /**
     * @dev Emitted every time the transaction cost limit percentage is set
     */
    event TxCostLimitPctSet(uint256 txCostLimitPct);

    /**
     * @dev Tells the gas price limit
     */
    function gasPriceLimit() external view returns (uint256);

    /**
     * @dev Tells the priority fee limit
     */
    function priorityFeeLimit() external view returns (uint256);

    /**
     * @dev Tells the transaction cost limit
     */
    function txCostLimit() external view returns (uint256);

    /**
     * @dev Tells the transaction cost limit percentage
     */
    function txCostLimitPct() external view returns (uint256);

    /**
     * @dev Sets the gas price limit
     * @param newGasPriceLimit New gas price limit to be set
     */
    function setGasPriceLimit(uint256 newGasPriceLimit) external;

    /**
     * @dev Sets the priority fee limit
     * @param newPriorityFeeLimit New priority fee limit to be set
     */
    function setPriorityFeeLimit(uint256 newPriorityFeeLimit) external;

    /**
     * @dev Sets the transaction cost limit
     * @param newTxCostLimit New transaction cost limit to be set
     */
    function setTxCostLimit(uint256 newTxCostLimit) external;

    /**
     * @dev Sets the transaction cost limit percentage
     * @param newTxCostLimitPct New transaction cost limit percentage to be set
     */
    function setTxCostLimitPct(uint256 newTxCostLimitPct) external;
}