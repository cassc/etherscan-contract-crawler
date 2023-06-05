// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;

import "./ThugDogs.sol";

contract ThugDogsMarket is ThugDogs {
    uint256 price;
    address recipient;

    constructor(
        string memory _baseURI,
        string memory _contractURI,
        uint256 _price
    ) ThugDogs(_baseURI, _contractURI) {
        price = _price;
    }

    modifier _isEnoughPay(uint256 amount) {
        require(
            price * amount <= msg.value,
            "ThugDogsMarket: msg.value is not enough"
        );
        _;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function buyTokens(address _to, uint256 amount)
        external
        payable
        _isEnoughPay(amount)
    {
        _mintTokens(_to, amount);
        payable(owner()).transfer(msg.value);
    }
}