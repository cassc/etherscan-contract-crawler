// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";

contract PassRelay is Ownable, Pausable {
    event PassPurchased(address indexed buyer, uint256 indexed baseId);
    uint256 public passPrice;

    constructor() {
        passPrice = 0.075 ether;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPassPrice(uint256 newPrice) public onlyOwner {
        passPrice = newPrice;
    }

    function purchase(uint256 baseId) public payable whenNotPaused {
        require(msg.value == passPrice, "PassRelay: invalid price");
        emit PassPurchased(msg.sender, baseId);
    }

    function withdrawAll() public onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "PassRelay: failed to transfer");
    }
}