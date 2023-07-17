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
    uint256 internal _initialGas;

    // Allows relaying transactions even if there is not enough balance in the Smart Vault to pay for the tx gas cost
    bool public isPermissiveModeActive;

    // Gas price limit, if surpassed it wont relay the transaction
    uint256 public gasPriceLimit;

    // Total cost limit expressed in `payingGasToken`, if surpassed it wont relay the transaction
    uint256 public totalCostLimit;

    // Address of the ERC20 token that will be used to pay the total tx cost
    address public payingGasToken;

    // List of allowed relayers indexed by address
    mapping (address => bool) public isRelayer;

    /**
     * @dev Emitted every time the permissive mode is changed
     */
    event PermissiveModeSet(bool active);

    /**
     * @dev Emitted every time the relayers list is changed
     */
    event RelayerSet(address indexed relayer, bool allowed);

    /**
     * @dev Emitted every time the relayer limits are set
     */
    event LimitsSet(uint256 gasPriceLimit, uint256 totalCostLimit, address payingGasToken);

    /**
     * @dev Modifier that can be used to reimburse the gas cost of the tagged function
     */
    modifier redeemGas() {
        _beforeCall();
        _;
        _afterCall();
    }

    /**
     * @dev Sets the relayed action permissive mode. If active, it won't fail when trying to redeem gas costs to the
     * relayer if the smart vault does not have enough balance. Sender must be authorized.
     * @param active Whether the permissive mode should be active or not
     */
    function setPermissiveMode(bool active) external auth {
        isPermissiveModeActive = active;
        emit PermissiveModeSet(active);
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
     * @dev Sets the relayer limits. Sender must be authorized.
     * @param _gasPriceLimit New gas price limit to be set
     * @param _totalCostLimit New total cost limit to be set
     * @param _payingGasToken New paying gas token to be set
     */
    function setLimits(uint256 _gasPriceLimit, uint256 _totalCostLimit, address _payingGasToken) external auth {
        require(_payingGasToken != address(0), 'PAYING_GAS_TOKEN_ZERO');
        gasPriceLimit = _gasPriceLimit;
        totalCostLimit = _totalCostLimit;
        payingGasToken = _payingGasToken;
        emit LimitsSet(_gasPriceLimit, _totalCostLimit, _payingGasToken);
    }

    /**
     * @dev Internal before call hook where limit validations are checked
     */
    function _beforeCall() internal {
        _initialGas = gasleft();
        require(isRelayer[msg.sender], 'SENDER_NOT_RELAYER');
        uint256 limit = gasPriceLimit;
        require(limit == 0 || tx.gasprice <= limit, 'GAS_PRICE_ABOVE_LIMIT');
    }

    /**
     * @dev Internal after call hook where tx cost is reimburse
     */
    function _afterCall() internal {
        uint256 totalGas = _initialGas - gasleft();
        uint256 totalCostNative = (totalGas + RelayedAction(this).BASE_GAS()) * tx.gasprice;

        uint256 limit = totalCostLimit;
        address payingToken = payingGasToken;
        // Total cost is rounded down to make sure we always match at least the threshold
        uint256 totalCostToken = totalCostNative.mulDown(_getPayingGasTokenPrice(payingToken));
        require(limit == 0 || totalCostToken <= limit, 'TX_COST_ABOVE_LIMIT');

        if (_shouldTryRedeemFromSmartVault(payingToken, totalCostToken)) {
            smartVault.withdraw(payingToken, totalCostToken, smartVault.feeCollector(), REDEEM_GAS_NOTE);
        }

        delete _initialGas;
    }

    /**
     * @dev Internal function to fetch the paying gas token rate from the Smart Vault's price oracle
     */
    function _getPayingGasTokenPrice(address token) private view returns (uint256) {
        bool isUsingNativeToken = _isWrappedOrNativeToken(token);
        return isUsingNativeToken ? FixedPoint.ONE : smartVault.getPrice(smartVault.wrappedNativeToken(), token);
    }

    /**
     * @dev Internal function to tell if the relayed action should try to redeem the gas cost from the Smart Vault
     * @param token Address of the token to pay the relayed gas cost
     * @param amount Amount of tokens to pay for the relayed gas cost
     */
    function _shouldTryRedeemFromSmartVault(address token, uint256 amount) private view returns (bool) {
        if (!isPermissiveModeActive) return true;
        return _balanceOf(token) >= amount;
    }
}