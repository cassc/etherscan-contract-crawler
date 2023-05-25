// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PublicSalesActivation is Ownable {
    uint256 public PUBLIC_SALES_START_TIMESTAMP;

    modifier isPublicSalesActive() {
        require(isPublicSalesActivated(), "Public Sale is not activated");
        _;
    }

    constructor() {}

    function isPublicSalesActivated() public view returns (bool) {
        return
            PUBLIC_SALES_START_TIMESTAMP > 0 && block.timestamp >= PUBLIC_SALES_START_TIMESTAMP;
    }

    // 1651975200 : Sun May 08 2022 02:00:00 GMT+0000
    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        PUBLIC_SALES_START_TIMESTAMP = _startTime;
    }
}