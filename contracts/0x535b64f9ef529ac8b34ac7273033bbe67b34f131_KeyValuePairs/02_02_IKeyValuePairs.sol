//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/**
 * A utility contract to log key / value pair events for the calling address.
 */
interface IKeyValuePairs {

    /**
     * Logs the given key / value pairs, along with the caller's address.
     *
     * @param _keys the keys
     * @param _values the values
     */
    function updateValues(string[] memory _keys, string[] memory _values) external;
}