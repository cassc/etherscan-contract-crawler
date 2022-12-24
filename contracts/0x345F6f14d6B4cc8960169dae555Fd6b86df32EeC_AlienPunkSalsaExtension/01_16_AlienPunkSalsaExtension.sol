//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract AlienPunkSalsa {
    function giftRandomized(address addr, uint256 quantity) public virtual;
    function transferOwnership(address newOwner) public virtual;
}

abstract contract DROOL {
    function burnFrom(address _from, uint256 _amount) external virtual;
}

contract AlienPunkSalsaExtension is Ownable, ReentrancyGuard {

    AlienPunkSalsa private immutable alienPunkSalsa;
    DROOL private immutable drool;
    uint256 public price = 1000 ether; // 1000 $DROOL
    bool public mintActive = false;

    constructor(address _alienPunkSalsa, address _drool) {
       alienPunkSalsa = AlienPunkSalsa(_alienPunkSalsa);
       drool = DROOL(_drool);
    }

    function mintWithDrool(uint256 quantity) external payable nonReentrant {
        require(mintActive, "Mint is not active");
        require(msg.sender == tx.origin, "No contracts");

        if(price > 0) {
            drool.burnFrom(msg.sender, quantity * price);
        }

        alienPunkSalsa.giftRandomized(msg.sender, quantity);
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMintActive(bool mintActive_) external onlyOwner {
        mintActive = mintActive_;
    }

    function returnOwnership() external onlyOwner {
        alienPunkSalsa.transferOwnership(msg.sender);
    }
}