// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TitanTiki is ERC1155, Ownable {
    using Counters for Counters.Counter;

    uint256 public constant TOTAL_TOKENS = 1000;
    uint256 public price = 100000000000000000;

    address private _payoutAddress;
    address private _devAddress;

    Counters.Counter private _tokenIdTracker;
    uint256 public reservedsLeft = 310;
    uint256 public threshold = 690;

    bool public saleIsActive = false;

    constructor(address payoutAddress, address devAddress)
        ERC1155("https://17pocvex2e.execute-api.us-east-1.amazonaws.com/token/{id}")
    {
        _payoutAddress = payoutAddress;
        _devAddress = devAddress;
    }

    // Owner Only
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pauseSale() public onlyOwner {
        saleIsActive = false;
    }

    function startSale(uint256 newThreshold) public onlyOwner {
        require(newThreshold > 0);
        threshold = newThreshold;
        saleIsActive = true;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function claimReserved(address to, uint256 amount) public onlyOwner {
        require(reservedsLeft >= amount, "no reserves left");
        require(tokensLeft() >= amount, "no tokens left");
        _mintMany(to, amount);
        reservedsLeft = reservedsLeft - amount;
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;

        uint256 devShare = contractBalance * 15 / 100;
        uint256 payoutShare = contractBalance - devShare;

        require(payable(_devAddress).send(devShare));
        require(payable(_payoutAddress).send(payoutShare));
    }

    // Internal Helpers
    function _mintMany(address to, uint256 amount) internal {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            ids[i] = _tokenIdTracker.current();
            amounts[i] = 1;
            _tokenIdTracker.increment();
        }

        _mintBatch(to, ids, amounts, "");
    }

    // Public View
    function tokensLeft() public view returns (uint256) {
        return TOTAL_TOKENS - _tokenIdTracker.current();
    }

    function nextTokenId() public view returns(uint256) {
        return _tokenIdTracker.current();
    }

    function tokenAmoundMinusReserved() public view returns(uint256) {
        return _tokenIdTracker.current() + reservedsLeft - 310;
    }

    // Public Tx
    function mint(uint256 amount) public payable {
        require(saleIsActive, "sale is not active");
        require(amount > 0, "amount out of bounds");
        require(amount <= 5, "amount out of bounds");
        require(threshold >= tokenAmoundMinusReserved() + amount, "will exceed threshold");
        require(tokensLeft() - reservedsLeft >= amount, "will exceed max tokens");
        require(msg.value >= price * amount, "incorrect eth value");

        _mintMany(msg.sender, amount);

        if (tokenAmoundMinusReserved() == threshold) {
            saleIsActive = false;
        }
    }

    // Overrides
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}