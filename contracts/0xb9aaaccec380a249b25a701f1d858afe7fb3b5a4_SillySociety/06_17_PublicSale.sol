// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PublicSale is Ownable, ReentrancyGuard{

    modifier isPublicSaleActive() {
        require(isPublicSaleActivated(), "Public Sale is not active yet");
        _;
    }

    uint256 public publicStart;


    constructor(uint256 _publicStart) {
        publicStart = _publicStart;
    }

    function isPublicSaleActivated() public view returns (bool) {
        return publicStart > 0 && block.timestamp >= publicStart;
    }

    function setTimeStampPublicSale(uint256 _publicStart) external onlyOwner nonReentrant{
        publicStart = _publicStart;
    }

}