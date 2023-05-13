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

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';

import './BaseAction.sol';

/**
 * @title RelayedAction
 * @dev Action that offers a relayed mechanism to allow reimbursing tx costs after execution in any ERC20 token.
 * This type of action at least require having withdraw permissions from the Smart Vault tied to it.
 */
abstract contract RelayedAction is BaseAction {
    using FixedPoint for uint256;

    // Base gas amount charged to cover default amounts
    // solhint-disable-next-line func-name-mixedcase
    function BASE_GAS() external view virtual returns (uint256);

    // Note to be used to mark tx cost payments
    bytes private constant REDEEM_GAS_NOTE = bytes('RELAYER');

    // Internal variable used to allow a better developer experience to reimburse tx gas cost
    uint256 private _initialGas;

    // Gas price limit expressed in the native token, if surpassed it wont relay the transaction
    uint256 public gasPriceLimit;

    // Total transaction cost limit expressed in the native token, if surpassed it wont relay the transaction
    uint256 public txCostLimit;

    // Allows relaying transactions even if there is not enough balance in the Smart Vault to pay for the tx gas cost
    bool public isPermissiveRelayedModeActive;

    // List of allowed relayers indexed by address
    mapping (address => bool) public isRelayer;

    /**
     * @dev Emitted every time the relayers list is changed
     */
    event RelayerSet(address indexed relayer, bool allowed);

    /**
     * @dev Emitted every time the relayer limits are set
     */
    event LimitsSet(uint256 gasPriceLimit, uint256 txCostLimit);

    /**
     * @dev Emitted every time the permissive relayed mode is changed
     */
    event PermissiveRelayedModeSet(bool active);

    /**
     * @dev Modifier that can be used to reimburse the gas cost of the tagged function paying in a specific token
     */
    modifier redeemGas(address token) {
        _initRelayedTx();
        _;
        _payRelayedTx(token);
    }

    /**
     * @dev Sets a relayer address. Sender must be authorized.
     * @param relayer Address of the relayer to be set
     * @param allowed Whether it should be allowed or not
     */
    function setRelayer(address relayer, bool allowed) external auth {
        isRelayer[relayer] = allowed;
        emit RelayerSet(relayer, allowed);
    }

    /**
     * @dev Sets the relayed action permissive relayed mode. If active, it won't fail when trying to redeem gas costs to the
     * relayer if the smart vault does not have enough balance. Sender must be authorized.
     * @param active Whether the permissive relayed mode should be active or not
     */
    function setPermissiveRelayedMode(bool active) external auth {
        isPermissiveRelayedModeActive = active;
        emit PermissiveRelayedModeSet(active);
    }

    /**
     * @dev Sets the relayer limits. Sender must be authorized.
     * @param _gasPriceLimit New gas price limit to be set
     * @param _txCostLimit New total cost limit to be set
     */
    function setLimits(uint256 _gasPriceLimit, uint256 _txCostLimit) external auth {
        gasPriceLimit = _gasPriceLimit;
        txCostLimit = _txCostLimit;
        emit LimitsSet(_gasPriceLimit, _txCostLimit);
    }

    /**
     * @dev Internal init hook used for relayed txs. It checks tx limit validations only when the sender is a relayer.
     */
    function _initRelayedTx() internal {
        if (!isRelayer[msg.sender]) return;
        _initialGas = gasleft();
        uint256 limit = gasPriceLimit;
        require(limit == 0 || tx.gasprice <= limit, 'GAS_PRICE_ABOVE_LIMIT');
    }

    /**
     * @dev Internal function to pay for a relayed tx. Only when the sender is marked as a relayer.
     * @param token Address of the token to use in order to pay the tx cost
     * @return Amount of tokens paid to reimburse the tx cost
     */
    function _payRelayedTx(address token) internal returns (uint256) {
        if (!isRelayer[msg.sender]) return 0;
        require(_initialGas > 0, 'RELAYED_TX_NOT_INITIALIZED');

        uint256 limit = txCostLimit;
        uint256 totalGas = _initialGas - gasleft();
        uint256 totalCostNative = (totalGas + RelayedAction(this).BASE_GAS()) * tx.gasprice;
        require(limit == 0 || totalCostNative <= limit, 'TX_COST_ABOVE_LIMIT');

        // Total cost is rounded down to make sure we always match at least the threshold
        uint256 price = _getNativeTokenPriceIn(token);
        uint256 totalCostToken = totalCostNative.mulDown(price);
        if (_balanceOf(token) >= totalCostToken || !isPermissiveRelayedModeActive) {
            smartVault.withdraw(token, totalCostToken, smartVault.feeCollector(), REDEEM_GAS_NOTE);
        }

        delete _initialGas;
        return totalCostToken;
    }

    /**
     * @dev Tells the price of the native token quoted in a another token
     * @param token Address of the token to quote the native token in
     */
    function _getNativeTokenPriceIn(address token) private view returns (uint256) {
        if (_isWrappedOrNativeToken(token)) return FixedPoint.ONE;
        return _getPrice(smartVault.wrappedNativeToken(), token);
    }
}