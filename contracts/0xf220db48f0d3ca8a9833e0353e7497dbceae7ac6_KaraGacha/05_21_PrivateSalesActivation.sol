// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PrivateSalesActivation is Ownable {
    uint256 public privateSalesStartTime;
    uint256 public privateSalesEndTime;

    modifier isPrivateSalesActive() {
        require(isPrivateSalesActivated(), "Private Sale is not activated");
        _;
    }

    constructor() {}

    function isPrivateSalesActivated() public view returns (bool) {
        return
            privateSalesStartTime > 0 &&
            privateSalesEndTime > 0 &&
            block.timestamp >= privateSalesStartTime &&
            block.timestamp <= privateSalesEndTime;
    }

    // 1652839200 : Wed May 18 2022 02:00:00 GMT+0000
    // 1652882400 : Wed May 18 2022 14:00:00 GMT+0000
    function setPrivateSalesTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _endTime >= _startTime,
            "End time should be later than start time"
        );
        privateSalesStartTime = _startTime;
        privateSalesEndTime = _endTime;
    }
}