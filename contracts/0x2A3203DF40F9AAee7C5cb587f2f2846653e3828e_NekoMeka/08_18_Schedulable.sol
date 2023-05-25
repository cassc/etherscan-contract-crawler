// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev Allow schedule start time for a contract
 */
abstract contract Schedulable {
    uint256 private _startTime;

    modifier whenSaleStarted() {
        require(hasSaleStarted(), "Schedulable: Sales not yet started");
        _;
    }

    modifier whenSaleNotStarted() {
        require(!hasSaleStarted(), "Schedulable: Sales already started");
        _;
    }

    constructor(uint256 _start) {
        _startTime = _start;
    }

    function startTime() external view returns (uint256) {
        return _startTime;
    }

    function _setStartTime(uint256 _start) internal {
        _startTime = _start;
    }

    function hasSaleStarted() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return _startTime > 0 && _startTime <= block.timestamp;
    }
}