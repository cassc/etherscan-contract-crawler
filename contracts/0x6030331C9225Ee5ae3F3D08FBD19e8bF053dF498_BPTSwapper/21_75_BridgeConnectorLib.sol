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

import '@mimic-fi/v2-bridge-connector/contracts/IBridgeConnector.sol';

/**
 * @title BridgeConnectorLib
 * @dev Library used to delegate-call bridge ops and decode return data correctly
 */
library BridgeConnectorLib {
    /**
     * @dev Delegate-calls a bridge to the bridge connector and decodes de expected data
     * IMPORTANT! This helper method does not check any of the given params, these should be checked beforehand.
     */
    function bridge(
        address connector,
        uint8 source,
        uint256 chainId,
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        bytes memory data
    ) internal {
        bytes memory bridgeData = abi.encodeWithSelector(
            IBridgeConnector.bridge.selector,
            source,
            chainId,
            token,
            amountIn,
            minAmountOut,
            recipient,
            data
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = connector.delegatecall(bridgeData);
        Address.verifyCallResult(success, returndata, 'BRIDGE_CALL_REVERTED');
    }
}