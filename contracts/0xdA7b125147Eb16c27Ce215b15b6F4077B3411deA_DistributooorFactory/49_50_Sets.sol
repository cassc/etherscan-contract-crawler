// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8 <0.9;

/// @title Sets
/// @author kevincharm
/// @notice Implementation of sets via circular linked list.
///     * Don't use address(0x1) as it is used as a special "head" pointer
///     * Use like this:
///         using Sets for Sets.Set;
///         Sets.Set internal animals;
///         ...
///         animals.init();
///         animals.add(0xd8da6bf26964af9d7eed9e03e53415d37aa96045);
library Sets {
    struct Set {
        mapping(address => address) ll;
        uint256 size;
    }

    address public constant OUROBOROS = address(0x1);

    error SetAlreadyInitialised();
    error SetNotInitialised();
    error ElementInvalid(address element);
    error ElementExists(address element);
    error ConsecutiveElementsRequired(address prevElement, address element);
    error ElementDoesNotExist(address element);

    function _isInitialised(Set storage set) private view returns (bool) {
        return set.ll[OUROBOROS] != address(0);
    }

    function init(Set storage set) internal {
        if (_isInitialised(set)) {
            revert SetAlreadyInitialised();
        }

        set.ll[OUROBOROS] = OUROBOROS;
    }

    function add(Set storage set, address element) internal {
        if (!_isInitialised(set)) {
            revert SetNotInitialised();
        }
        if (element == address(0) || element == OUROBOROS) {
            revert ElementInvalid(element);
        }
        if (set.ll[element] != address(0)) {
            revert ElementExists(element);
        }
        set.ll[element] = set.ll[OUROBOROS];
        set.ll[OUROBOROS] = element;
        ++set.size;
    }

    function del(
        Set storage set,
        address prevElement,
        address element
    ) internal {
        if (!_isInitialised(set)) {
            revert SetNotInitialised();
        }
        if (element != set.ll[prevElement]) {
            revert ConsecutiveElementsRequired(prevElement, element);
        }
        if (element == address(0) || element == OUROBOROS) {
            revert ElementInvalid(element);
        }
        if (set.ll[element] == address(0)) {
            revert ElementDoesNotExist(element);
        }

        set.ll[prevElement] = set.ll[element];
        set.ll[element] = address(0);
        --set.size;
    }

    function has(
        Set storage set,
        address element
    ) internal view returns (bool) {
        if (!_isInitialised(set)) {
            revert SetNotInitialised();
        }
        return set.ll[element] != address(0);
    }

    function toArray(Set storage set) internal view returns (address[] memory) {
        if (!_isInitialised(set)) {
            revert SetNotInitialised();
        }

        if (set.size == 0) {
            return new address[](0);
        }

        address[] memory array = new address[](set.size);
        address element = set.ll[OUROBOROS];
        for (uint256 i; i < array.length; ++i) {
            array[i] = element;
            element = set.ll[element];
        }
        return array;
    }
}