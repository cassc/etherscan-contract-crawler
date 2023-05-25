// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DASalesActivation is Ownable {
    uint256 public DASalesStartTime;
    uint256 public DASalesEndTime;

    modifier isDASalesActive() {
        require(isDASalesActivated(), "DA Sale is not activated");
        _;
    }

    constructor() {}

    function isDASalesActivated() public view returns (bool) {
        return
            DASalesStartTime > 0 &&
            DASalesEndTime > 0 &&
            block.timestamp >= DASalesStartTime &&
            block.timestamp <= DASalesEndTime;
    }

    // 1651845600 : Fri May 06 2022 14:00:00 GMT+0000
    // 1651867200 : Fri May 06 2022 20:00:00 GMT+0000
    function setDASalesTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _endTime >= _startTime,
            "End time should be later than start time"
        );
        DASalesStartTime = _startTime;
        DASalesEndTime = _endTime;
    }
}