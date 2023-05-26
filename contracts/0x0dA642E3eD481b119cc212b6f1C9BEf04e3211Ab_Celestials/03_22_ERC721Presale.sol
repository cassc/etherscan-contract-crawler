// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../../access/Whitelistable.sol";
import "../../access/TXLimiter.sol";
import "../../access/PurchaseLimiter.sol";
import "../ERC721Collection.sol";

abstract contract ERC721Presale is Ownable, ERC721Collection, PurchaseLimiter, Whitelistable {
    using SafeMath for uint256;

    bool public presaleIsActive = false;
    uint256 public presaleSupply = 4000;
    uint256 public presalePrice = 55 * 1e15; // 0.055 ETH


    function setPresaleState(bool state) public onlyOwner {
        presaleIsActive = state;
    }

    function setPresaleSupply(uint256 supply) public onlyOwner {
        require(supply > 0 && supply <= maxSupply, "InvaliPresaleSupply");
        presaleSupply = supply;
    }

    function setPresalePrice(uint256 price) public onlyOwner {
        require(price > 0, "InvaliPresalePrice");
        presalePrice = price;
    }

    function mintPresale(bytes32 leaf, bytes32[] memory proof, uint256 quantity) public payable {
        address to = _msgSender();

        require(presaleIsActive, "PresaleNotActive");
        require(totalSupply().add(quantity) <= presaleSupply, "PurchaseExeedsPresaleSupply");
        require(presalePrice.mul(quantity) <= msg.value, "IncorrectPresaleValue");

        addPresalePurchaseFor(to, quantity);
        checkWhitelisted(to, leaf, proof);

        mint(to, quantity);
    }
}