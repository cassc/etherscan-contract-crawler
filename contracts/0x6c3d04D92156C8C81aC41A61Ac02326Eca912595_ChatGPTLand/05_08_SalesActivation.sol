// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

// sales config
contract SalesActivation is Ownable {

    // public sales start time
    uint256 public publicSalesStartTime;

    // public sales end time
    uint256 public publicSalesEndTime;

    // pre sales start time
    uint256 public preSalesStartTime;

    // pre sales end time
    uint256 public preSalesEndTime;

    constructor() {}

    // ------------------------------------------- public sales
    // set public sales time
    function setPublicSalesTime(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(
            _endTime >= _startTime,
            "Public sales: End time should be later than start time"
        );
        publicSalesStartTime = _startTime;
        publicSalesEndTime = _endTime;
    }

    // is public sales activated
    function isPublicSalesActivated() public view returns (bool) {
        return
            publicSalesStartTime > 0 &&
            publicSalesEndTime > 0 &&
            block.timestamp >= publicSalesStartTime &&
            block.timestamp <= publicSalesEndTime;
    }

    // is public sales activated (modifier)
    modifier isPublicSalesActive() {
        require(
            isPublicSalesActivated(),
            "Public sales: Sale is not activated"
        );
        _;
    }

    // ------------------------------------------- pre sales
    // set pre sales time
    function setPreSalesTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(
            _endTime >= _startTime,
            "Pre sales: End time should be later than start time"
        );
        preSalesStartTime = _startTime;
        preSalesEndTime = _endTime;
    }


    // is pre sales active
    modifier isPreSalesActive() {
        require(
            isPreSalesActivated(),
            "Pre sales: Sale is not activated"
        );
        _;
    }

    // is pre sales activated
    function isPreSalesActivated() public view returns (bool) {
        return
            preSalesStartTime > 0 &&
            preSalesEndTime > 0 &&
            block.timestamp >= preSalesStartTime &&
            block.timestamp <= preSalesEndTime;
    }


 
}