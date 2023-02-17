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

import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v2-strategies/contracts/IStrategy.sol';

/**
 * @title StrategyLib
 * @dev Library used to delegate-call to strategy and decode return data correctly
 */
library StrategyLib {
    /**
     * @dev Delegate-calls a claim to a strategy and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function claim(address strategy, bytes memory data) internal returns (address[] memory, uint256[] memory) {
        bytes memory claimData = abi.encodeWithSelector(IStrategy.claim.selector, data);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = strategy.delegatecall(claimData);
        Address.verifyCallResult(success, returndata, 'CLAIM_CALL_REVERTED');
        return abi.decode(returndata, (address[], uint256[]));
    }

    /**
     * @dev Delegate-calls a join to a strategy and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function join(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) internal returns (address[] memory tokensOut, uint256[] memory amountsOut, uint256 value) {
        bytes memory joinData = abi.encodeWithSelector(IStrategy.join.selector, tokensIn, amountsIn, slippage, data);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = strategy.delegatecall(joinData);
        Address.verifyCallResult(success, returndata, 'JOIN_CALL_REVERTED');
        return abi.decode(returndata, (address[], uint256[], uint256));
    }

    /**
     * @dev Delegate-calls a exit to a strategy and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function exit(
        address strategy,
        address[] memory tokensIn,
        uint256[] memory amountsIn,
        uint256 slippage,
        bytes memory data
    ) internal returns (address[] memory tokensOut, uint256[] memory amountsOut, uint256 value) {
        bytes memory exitData = abi.encodeWithSelector(IStrategy.exit.selector, tokensIn, amountsIn, slippage, data);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = strategy.delegatecall(exitData);
        Address.verifyCallResult(success, returndata, 'EXIT_CALL_REVERTED');
        return abi.decode(returndata, (address[], uint256[], uint256));
    }
}