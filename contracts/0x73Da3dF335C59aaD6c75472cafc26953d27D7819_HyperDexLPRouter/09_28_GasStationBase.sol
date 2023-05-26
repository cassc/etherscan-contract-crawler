// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {GasStationRecipient} from "./GasStationRecipient.sol";

abstract contract GasStationBase is GasStationRecipient {
    /**
     * @dev Forwards calls to the this contract and extracts a fee based on provided arguments
     * @param msgData The byte data representing a mint using the original contract.
     * This is either recieved from the Multiswap API directly or we construct it
     * in order to perform a single swap trade
     */
    function route(bytes calldata msgData) external returns (bytes memory) {
        (bool success, bytes memory resultData) = address(this).call(msgData);

        if (!success) {
            _revertWithData(resultData);
        }

        _returnWithData(resultData);
    }

    /**
     * @dev Revert with arbitrary bytes.
     * @param data Revert data.
     */
    function _revertWithData(bytes memory data) internal pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    /**
     * @dev Return with arbitrary bytes.
     */
    function _returnWithData(bytes memory data) internal pure {
        assembly {
            return(add(data, 32), mload(data))
        }
    }
}