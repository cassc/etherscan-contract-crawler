// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

library FixedSizeQueue {
    /*
        Queue with fixed sized, determined by '_maxLength' passed to each function.
        Idea bases on determined number of slots set on circle, so it has no start nor end.
        Once it starts to fill more and more slots are fulfilled until it reach its capacity,
        so "length" is growing. "beginningIndex" indicates where on circle queue has currently beginning
        and sum of "beginningIndex" and "length" indicates slot which is right after the last element in queue.
        Because it is circle index of next element must be checked if it is bigger than max capacity,
        if yes, then it has to be redirect to the beginning of the array - it is done by modulo operation.
        
        Example:
        Imagine state of queue as follows:
        |0|1|2|3|4|5|6|7| <- indexes
        |_|_|_|_|4|7|2|_| <- values in slots

        when you push back 2 values by following instructions:
        queue.pushBack(2);
        queue.pushBack(9);

        final statue should look like that:
        |0|1|2|3|4|5|6|7| <- indexes
        |9|_|_|_|4|7|2|2| <- values in slots
     */

    error TooManyToPop(uint256 number, uint256 length);
    error IndexOutOfRange(uint256 index);
    error CantFitMoreElements();

    struct BytesContainer {
        uint256 beginningIndex;
        uint256 length;
        mapping(uint256 => bytes) elements;
    }

    function pushBack(
        BytesContainer storage _container,
        bytes memory _element,
        uint256 _maxLength
    ) internal {

        if (_container.length == _maxLength) {
            revert CantFitMoreElements();
        }

        // count internal index - check if it crosses the last element of the array,
        // if yes, redirect it to the beginning by modulo
        uint256 index_ = (_container.beginningIndex + _container.length) % _maxLength;
        _container.elements[index_] = _element;
        _container.length += 1;

    }

    function popFront(
        BytesContainer storage _container,
        uint256 _number,
        uint256 _maxLength
    ) internal {

        if (_number > _container.length) {
            revert TooManyToPop(_number, _container.length);
        }

        // elements are not being delete in order to safe gas
        _container.beginningIndex = (_container.beginningIndex + _number) % _maxLength;
        _container.length -= _number;

    }

    function at(
        BytesContainer storage _container,
        uint256 _index,
        uint256 _maxLength
    ) internal view returns (bytes memory value) {

        if (_container.length <= _index) {
            revert IndexOutOfRange(_index);
        }
        uint256 internalIndex_ = (_container.beginningIndex + _index) % _maxLength;
        return _container.elements[internalIndex_];

    }
}