// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/ISoulinkMinter.sol";
import "./interfaces/IDiscountDB.sol";

contract SoulinkMinter is Ownable, ISoulinkMinter {
    ISoulink public immutable soulink;
    uint96 public mintPrice;
    address public feeTo;
    uint96 public limit;
    address public discountDB;

    constructor(ISoulink _soulink) {
        soulink = _soulink;
        feeTo = msg.sender;
        limit = type(uint96).max;
        mintPrice = 0.1 ether;

        emit SetFeeTo(msg.sender);
        emit SetLimit(type(uint96).max);
        emit SetMintPrice(0.1 ether);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        require(feeTo != _feeTo, "UNCHANGED");
        feeTo = _feeTo;
        emit SetFeeTo(_feeTo);
    }

    function setLimit(uint96 _limit) external onlyOwner {
        require(limit != _limit, "UNCHANGED");
        limit = _limit;
        emit SetLimit(_limit);
    }

    function setMintPrice(uint96 _price) external onlyOwner {
        require(mintPrice != _price, "UNCHANGED");
        mintPrice = _price;
        emit SetMintPrice(_price);
    }

    function setDiscountDB(address db) external onlyOwner {
        require(discountDB != db, "UNCHANGED");
        discountDB = db;
        emit SetDiscountDB(db);
    }

    function mint(bool discount, bytes calldata data) public payable returns (uint256 id) {
        require(soulink.totalSupply() < limit, "LIMIT_EXCEEDED");
        uint256 _mintPrice = mintPrice;
        if (discount) {
            require(discountDB != address(0), "NO_DISCOUNTDB");
            uint16 dcRate = IDiscountDB(discountDB).getDiscountRate(msg.sender, data);
            _mintPrice = (_mintPrice * (10000 - dcRate)) / 10000;
        }
        require(msg.value == _mintPrice, "INVALID_MINTPRICE");
        id = soulink.mint(msg.sender);
        Address.sendValue(payable(feeTo), msg.value);
    }
}