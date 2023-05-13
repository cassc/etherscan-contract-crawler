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

import '@mimic-fi/v2-helpers/contracts/utils/ERC20Helpers.sol';

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/OracledAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';

import './IProtocolFeeWithdrawer.sol';

contract Claimer is BaseAction, OracledAction, RelayedAction, TokenThresholdAction {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 72e3;

    address public payingGasToken;
    address public protocolFeeWithdrawer;

    event PayingGasTokenSet(address indexed payingGasToken);
    event ProtocolFeeWithdrawerSet(address indexed protocolFeeWithdrawer);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function getClaimableBalance(address token) public view returns (uint256) {
        return ERC20Helpers.balanceOf(token, protocolFeeWithdrawer);
    }

    function setPayingGasToken(address newPayingGasToken) external auth {
        require(newPayingGasToken != address(0), 'CLAIMER_PAYING_GAS_TOKEN_ZERO');
        payingGasToken = newPayingGasToken;
        emit PayingGasTokenSet(newPayingGasToken);
    }

    function setProtocolFeeWithdrawer(address newProtocolFeeWithdrawer) external auth {
        require(newProtocolFeeWithdrawer != address(0), 'CLAIMER_WITHDRAWER_ADDRESS_ZERO');
        protocolFeeWithdrawer = newProtocolFeeWithdrawer;
        emit ProtocolFeeWithdrawerSet(newProtocolFeeWithdrawer);
    }

    function call(address token) external auth nonReentrant redeemGas(payingGasToken) {
        require(payingGasToken != address(0), 'CLAIMER_PAYING_GAS_TOKEN_ZERO');
        require(token != address(0), 'CLAIMER_TOKEN_ADDRESS_ZERO');
        require(!Denominations.isNativeToken(token), 'CLAIMER_NATIVE_TOKEN');

        uint256 amount = getClaimableBalance(token);
        _validateThreshold(token, amount);

        // solhint-disable-next-line avoid-low-level-calls
        smartVault.call(protocolFeeWithdrawer, _buildData(token, amount), 0, new bytes(0));
        emit Executed();
    }

    function _buildData(address token, uint256 amount) internal view returns (bytes memory) {
        address[] memory tokens = new address[](1);
        tokens[0] = token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        return
            abi.encodeWithSelector(
                IProtocolFeeWithdrawer.withdrawCollectedFees.selector,
                tokens,
                amounts,
                address(smartVault)
            );
    }

    function _getPrice(address base, address quote)
        internal
        view
        override(BaseAction, OracledAction)
        returns (uint256)
    {
        return OracledAction._getPrice(base, quote);
    }
}