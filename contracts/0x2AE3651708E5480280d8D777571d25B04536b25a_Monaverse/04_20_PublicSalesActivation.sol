// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PublicSalesActivation is Ownable {
    bool public isPublicSalesActivated;

    modifier isPublicSalesActive() {
      require(isPublicSalesActivated, "PublicSalesActivation: Sale is not activated");
      _;
    }

    constructor() {}

    function togglePublicSalesStatus() external onlyOwner {
        isPublicSalesActivated = !isPublicSalesActivated;
    }
}