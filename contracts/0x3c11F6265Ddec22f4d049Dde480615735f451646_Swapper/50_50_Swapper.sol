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

import { Pausable } from '@openzeppelin/contracts/security/Pausable.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { Address } from '@openzeppelin/contracts/utils/Address.sol';
import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import { Denominations } from '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import { ISmartVault } from '@mimic-fi/v2-smart-vault/contracts/ISmartVault.sol';
import { BaseAction } from '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';

/**
 * @title Swapper
 * @dev Public swapper action. This action allows any user to leverage a public smart vault to perform arbitray swaps.
 */
contract Swapper is BaseAction, Pausable {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    // Empty bytes array constant
    bytes private constant NO_DATA = new bytes(0);

    // Enumerable set of allowed sources
    EnumerableSet.UintSet private sources;

    /**
     * @dev Emitted every time a source is allowed or disallowed
     */
    event SourceSet(uint256 indexed source, bool allowed);

    /**
     * @dev Creates a new swapper action
     * @param admin Address that will be granted with admin permissions
     * @param registry Address of the Mimic Registry
     */
    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Tells the list of allowed sources
     */
    function getAllowedSources() external view returns (uint256[] memory) {
        return sources.values();
    }

    /**
     * @dev Tells whether a source is allowed or not
     * @param source Number identifying the source being queried
     */
    function isSourceAllowed(uint256 source) public view returns (bool) {
        return sources.contains(source);
    }

    /**
     * @dev Change a source allowance. Sender must be authorized.
     * @param source Number identifying the source to be set
     * @param allowed Whether the source should be allowed or not
     * @return success True if the source was actually added or removed from the list of allowed sources
     */
    function setSource(uint256 source, bool allowed) external auth returns (bool success) {
        require(source <= type(uint8).max, 'SWAPPER_INVALID_SOURCE_ID');
        success = allowed ? sources.add(source) : sources.remove(source);
        if (success) emit SourceSet(source, allowed);
    }

    /**
     * @dev Pause the swap action. Sender must be authorized.
     */
    function pause() external auth {
        _pause();
    }

    /**
     * @dev Unpause the swap action. Sender must be authorized.
     */
    function unpause() external auth {
        _unpause();
    }

    /**
     * @dev Swaps two tokens
     * @param source Source where the swap will be executed.
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut expected to be received
     * @param data Extra data that may enable or not different behaviors depending on the source picked
     */
    function call(
        uint8 source,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes memory data
    ) external payable nonReentrant whenNotPaused {
        require(isSourceAllowed(source), 'SWAPPER_SOURCE_NOT_ALLOWED');
        require(tokenIn != tokenOut, 'SWAPPER_SAME_TOKENS');
        require(tokenIn != address(0), 'SWAPPER_TOKEN_IN_ZERO');
        require(tokenOut != address(0), 'SWAPPER_TOKEN_OUT_ZERO');
        require(amountIn > 0, 'SWAPPER_AMOUNT_IN_ZERO');
        require(minAmountOut > 0, 'SWAPPER_MIN_AMOUNT_OUT_ZERO');

        // Final swap amount in is either the wrapped amount in case token in is the native token,
        // or the amount collected by the smart vault in case it is another ERC20 token
        uint256 swapAmountIn;
        if (Denominations.isNativeToken(tokenIn)) {
            require(msg.value == amountIn, 'SWAPPER_UNEXPECTED_VALUE');
            payable(address(smartVault)).sendValue(amountIn);
            swapAmountIn = smartVault.wrap(amountIn, NO_DATA);
        } else {
            require(msg.value == 0, 'SWAPPER_VALUE_GT_ZERO');
            require(IERC20(tokenIn).allowance(msg.sender, address(smartVault)) >= amountIn, 'SWAPPER_BAD_ALLOWANCE');
            swapAmountIn = smartVault.collect(tokenIn, msg.sender, amountIn, NO_DATA);
        }

        // Note that the swap should only be executed if this is not actually a wrap/unwrap only action
        // In that case, the action is already covered by the wrap (above) or unwrap (below)
        uint256 amountOut;
        address swapTokenIn = _wrappedIfNative(tokenIn);
        address swapTokenOut = _wrappedIfNative(tokenOut);
        if (swapTokenIn == swapTokenOut) {
            amountOut = swapAmountIn;
            require(amountOut >= minAmountOut, 'SWAPPER_WRAP_MIN_AMOUNT_OUT');
        } else {
            amountOut = smartVault.swap(
                source,
                swapTokenIn,
                swapTokenOut,
                swapAmountIn,
                ISmartVault.SwapLimit.MinAmountOut,
                minAmountOut,
                data
            );
        }

        // Finally unwrap if necessary and withdraw token out as requested to the sender
        uint256 toWithdraw = Denominations.isNativeToken(tokenOut) ? smartVault.unwrap(amountOut, NO_DATA) : amountOut;
        smartVault.withdraw(tokenOut, toWithdraw, msg.sender, NO_DATA);
        emit Executed();
    }
}