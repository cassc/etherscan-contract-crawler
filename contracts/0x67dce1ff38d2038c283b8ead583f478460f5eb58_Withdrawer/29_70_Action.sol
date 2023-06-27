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

import './IAction.sol';
import './base/BaseAction.sol';
import './base/RelayedAction.sol';
import './base/OracledAction.sol';
import './base/TimeLockedAction.sol';
import './base/TokenIndexedAction.sol';
import './base/TokenThresholdAction.sol';

/**
 * @title Action
 * @dev Shared components across all actions
 */
abstract contract Action is
    IAction,
    BaseAction,
    RelayedAction,
    OracledAction,
    TimeLockedAction,
    TokenIndexedAction,
    TokenThresholdAction
{
    /**
     * @dev Action config params. Only used in the constructor.
     */
    struct ActionConfig {
        BaseConfig baseConfig;
        RelayConfig relayConfig;
        OracleConfig oracleConfig;
        TimeLockConfig timeLockConfig;
        TokenIndexConfig tokenIndexConfig;
        TokenThresholdConfig tokenThresholdConfig;
    }

    /**
     * @dev Creates a new action
     */
    constructor(ActionConfig memory config)
        BaseAction(config.baseConfig)
        RelayedAction(config.relayConfig)
        OracledAction(config.oracleConfig)
        TimeLockedAction(config.timeLockConfig)
        TokenIndexedAction(config.tokenIndexConfig)
        TokenThresholdAction(config.tokenThresholdConfig)
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Fetches a price for base/quote pair. It prioritizes on-chain oracle data.
     */
    function _getPrice(address base, address quote)
        internal
        view
        virtual
        override(BaseAction, OracledAction)
        returns (uint256)
    {
        return base == quote ? FixedPoint.ONE : OracledAction._getPrice(base, quote);
    }

    /**
     * @dev Hook to be called before the action call starts.
     */
    function _beforeAction(address token, uint256 amount)
        internal
        virtual
        override(BaseAction, RelayedAction, TimeLockedAction, TokenIndexedAction, TokenThresholdAction)
    {
        BaseAction._beforeAction(token, amount);
        RelayedAction._beforeAction(token, amount);
        TimeLockedAction._beforeAction(token, amount);
        TokenIndexedAction._beforeAction(token, amount);
        TokenThresholdAction._beforeAction(token, amount);
    }

    /**
     * @dev Hook to be called after the action call has finished.
     */
    function _afterAction(address token, uint256 amount)
        internal
        virtual
        override(BaseAction, RelayedAction, TimeLockedAction)
    {
        TimeLockedAction._afterAction(token, amount);
        BaseAction._afterAction(token, amount);
        RelayedAction._afterAction(token, amount);
    }
}