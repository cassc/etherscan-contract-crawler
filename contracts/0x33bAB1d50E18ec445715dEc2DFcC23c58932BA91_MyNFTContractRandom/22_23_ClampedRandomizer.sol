//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ClampedRandomizer {
    uint256 private _scopeIndex = 0; //Clamping cache for random TokenID generation in the anti-sniping algo
    uint256 private immutable _scopeCap; //Size of initial randomized number pool & max generated value (zero indexed)
    mapping(uint256 => uint256) _swappedIDs; //TokenID cache for random TokenID generation in the anti-sniping algo

    constructor(uint256 scopeCap) {
        _scopeCap = scopeCap;
    }

    function _genClampedNonce() internal virtual returns (uint256) {
        uint256 scope = _scopeCap - _scopeIndex;
        uint256 swap;
        uint256 result;

        uint256 i = randomNumber() % scope;

        //Setup the value to swap in for the selected number
        if (_swappedIDs[scope - 1] == 0) {
            swap = scope - 1;
        } else {
            swap = _swappedIDs[scope - 1];
        }

        //Select a random number, swap it out with an unselected one then shorten the selection range by 1
        if (_swappedIDs[i] == 0) {
            result = i;
            _swappedIDs[i] = swap;
        } else {
            result = _swappedIDs[i];
            _swappedIDs[i] = swap;
        }
        _scopeIndex++;
        return result;
    }

    function randomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
}