// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PublicSalesActivation is Ownable {
    uint256 public publicSalesStartTime;

    modifier isPublicSalesActive() {
        require(isPublicSalesActivated(), "Public Sale is not activated");
        _;
    }

    constructor() {}

    function isPublicSalesActivated() public view returns (bool) {
        return
            publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime;
    }

    // 1652882400 : Wed May 18 2022 14:00:00 GMT+0000
    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        publicSalesStartTime = _startTime;
    }
}