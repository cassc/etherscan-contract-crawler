/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

library ArrayUtils {
    /**
     * Returns the index of the element 'a' in the _array provided. It also returns true if
     * the element was found, and false if not, as -1 is not a possible output.
     *
     * @param _array    Array to check
     * @param a         Element to check in array
     *
     * @return A tuple with the index of the element, and a bool
     */
    function indexOf(address[] memory _array, address a) internal pure returns (uint256, bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; i++) {
            if (_array[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     * Returns true if the element 'a' is in the _array provided, and false otherwise.
     *
     * @param _array    Array to check
     * @param a         Element to check in array
     *
     * @return True if the element is present in the array
     */
    function contains(address[] memory _array, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(_array, a);
        return isIn;
    }

    /**
     * Returns true if the _array contains duplicates, and false otherwise.
     *
     * @param _array    Array to check
     *
     * @return True if there are duplicates in the array
     */
    function hasDuplicate(address[] memory _array) internal pure returns (bool) {
        require(_array.length > 0, "_array is empty");

        for (uint256 i = 0; i < _array.length - 1; i++) {
            address current = _array[i];
            for (uint256 j = i + 1; j < _array.length; j++) {
                if (current == _array[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Removes the element 'a' from the memory _array if present. Will revert if the
     * element is not present. Returns a new array.
     *
     * @param _array    Array to check
     * @param a         Element to remove
     *
     * @return A new array without the element
     */
    function remove(address[] memory _array, address a) internal pure returns (address[] memory) {
        (uint256 index, bool isIn) = indexOf(_array, a);
        if (!isIn) {
            revert("Address not in array");
        } else {
            (address[] memory _newArray,) = pop(_array, index);
            return _newArray;
        }
    }

    /**
     * Removes the element 'a' from the storage _array if present. Will revert if the
     * element is not present. Moves the last element in the _array to the index in
     * which the element 'a' is present. Changes the array in-place.
     *
     * @param _array    Array to modify
     * @param a         Element to remove
     */
    function removeStorage(address[] storage _array, address a) internal {
        (uint256 index, bool isIn) = indexOf(_array, a);
        if (!isIn) {
            revert("Address not in array");
        } else {
            uint256 lastIndex = _array.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) _array[index] = _array[lastIndex];
            _array.pop();
        }
    }

    /**
     * Removes from the array the element in the index specified. Returns a new array and
     * the element removed, as a tuple.
     *
     * @param _array    Array to modify
     * @param index     Index of element to remove
     *
     * @return New array amd the removed element, as a tuple
     */
    function pop(address[] memory _array, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = _array.length;
        require(index < _array.length, "Index must be < _array length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = _array[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = _array[j];
        }
        return (newAddresses, _array[index]);
    }
}