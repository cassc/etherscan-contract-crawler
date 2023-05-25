// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title The contract to provide basic timelock functionality
abstract contract TimeLock {
    /// @dev Start timestamp, second since unix epoch
    uint256 private _start;
    /// @dev End timestamp, second since unix epoch
    uint256 private _end;

    constructor(uint256 start, uint256 end) {
        _start = start;
        _end = end;
    }

    function _setTimeLockData(uint256 start, uint256 end) internal {
        _start = start;
        _end = end;
    }

    function startTimestamp() public view virtual returns (uint256) {
        return _start;
    }

    function endTimestamp() public view virtual returns (uint256) {
        return _end;
    }

    /// @notice Modifier to allow execution if we are in the specified interval
    modifier onlyMintRunning() {
        require(block.timestamp >= _start, "T0");
        require(block.timestamp <= _end, "T1");
        _;
    }
}