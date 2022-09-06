// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

// public sales config
contract PublicSalesActivation is Ownable {
    uint256 public publicSalesStartTime;

    modifier isPublicSalesActive() {
        require(
            isPublicSalesActivated(),
            "Public sales: Sale is not activated"
        );
        _;
    }

    constructor() {}

    // is public sales activated
    function isPublicSalesActivated() public view returns (bool) {
        return
            publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime;
    }

    // set publicsales time
    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        publicSalesStartTime = _startTime;
    }
 
}