//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title FisherYatesBucket
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Contract allowing to easily get random stuff from a bucket using FisherYatesShuffle
contract FisherYatesBucket {
    /// @notice bucket size
    uint256 public bucketSize = 1000;

    /// @dev the current bucket
    mapping(uint256 => uint256) private _bucket;

    function _pickNextIndex() internal returns (uint256 selectedIndex) {
        uint256 bucketSize_ = bucketSize;

        uint256 seed = _seed(bucketSize_);
        uint256 index = 1 + (seed % bucketSize_);

        // select value at index
        selectedIndex = _bucket[index];
        if (selectedIndex == 0) {
            // if 0, it was never initialized, so value is index
            selectedIndex = index;
        }

        // if the index picked is not the last one
        if (index != bucketSize_) {
            // swap last value of the bucket into the index that was just picked
            uint256 temp = _bucket[bucketSize_];
            if (temp != 0) {
                _bucket[index] = temp;
                delete _bucket[bucketSize_];
            } else {
                _bucket[index] = bucketSize_;
            }
        } else if (index != selectedIndex) {
            // else of the index is the last one, but the value wasn't 0, delete
            delete _bucket[bucketSize_];
        }

        // decrease bucket size
        bucketSize = bucketSize_ - 1;
    }

    function _seed(uint256 size) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, size)));
    }
}