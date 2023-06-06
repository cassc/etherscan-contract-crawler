//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { IKeyValuePairs } from "./interfaces/IKeyValuePairs.sol";

/**
 * Implementation of [IKeyValuePairs](./interfaces/IKeyValuePairs.md), a utility 
 * contract to log key / value pair events for the calling address.
 */
contract KeyValuePairs is IKeyValuePairs {

    event ValueUpdated(address indexed theAddress, string key, string value);

    error IncorrectValueCount();

    /** @inheritdoc IKeyValuePairs*/
    function updateValues(string[] memory _keys, string[] memory _values) external {

        uint256 keyCount = _keys.length;

        if (keyCount != _values.length)
            revert IncorrectValueCount();

        for (uint256 i; i < keyCount; ) {
            emit ValueUpdated(msg.sender, _keys[i], _values[i]);
            unchecked {
                ++i;
            }
        }
    }
}