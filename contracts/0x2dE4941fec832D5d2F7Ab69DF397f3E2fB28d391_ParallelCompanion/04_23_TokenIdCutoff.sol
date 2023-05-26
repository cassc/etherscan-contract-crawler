// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITokenIdCutoff {
    event CutoffTokenIdSet(uint256 value);
}

/**
 * @notice Contract that keeps track of token id cutoffs, one use case being limiting token supplies
 */
contract TokenIdCutoff is ITokenIdCutoff {
    /**
     * The cutoff can only increase
     *
     * @param cutoff The invalid cutoff
     */
    error InvalidCutoff(uint256 cutoff);
    uint256 public _cutoffTokenId;

    function cutoffTokenId() public view virtual returns (uint256) {
        return _cutoffTokenId;
    }

    function _setCutoffTokenId(uint256 _newCutoffTokenId) internal virtual {
        if (_newCutoffTokenId <= _cutoffTokenId) {
            revert InvalidCutoff(_newCutoffTokenId);
        }
        _cutoffTokenId = _newCutoffTokenId;

        emit CutoffTokenIdSet(_newCutoffTokenId);
    }
}