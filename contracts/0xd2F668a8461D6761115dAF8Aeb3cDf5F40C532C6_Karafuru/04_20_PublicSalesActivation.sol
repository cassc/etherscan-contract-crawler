// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PublicSalesActivation is Ownable {
    uint256 public publicSalesStartTime;

    modifier isPublicSalesActive() {
        require(
            isPublicSalesActivated(),
            "PublicSalesActivation: Sale is not activated"
        );
        _;
    }

    constructor() {}

    function isPublicSalesActivated() public view returns (bool) {
        return
            publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime;
    }

    // 1644069600: start time at 05 Feb 2022 (2 PM UTC+0) in seconds
    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        publicSalesStartTime = _startTime;
    }
}