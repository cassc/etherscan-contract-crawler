// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WithdrawFairlyOrigin is Ownable {
    using SafeMath for uint256;

    struct Part {
        address wallet;
        uint256 salePart;
        uint256 royaltiesPart;
    }

    Part[] public parts;

    bool public saleIsOver = false;

    constructor(){
        parts.push(Part(0x82acCD007449E15dD8566D8199B8C9593403517b, 200, 150)); // miinded 20 15
        parts.push(Part(0x65720Bb1f5d0bAD279e6fb3e03B116771D0321FC, 345, 375)); // jimmy 34.5 37.5
        parts.push(Part(0x69F3c8695CCC7c77EdaA9459d9Dbc9A444Cf3c5b, 85, 110)); // Charles 8.5 11
        parts.push(Part(0x7E0EDC5639b84E5F2072c968f5c424e2b58A5A1A, 140, 60)); // Yvick 14 6
        parts.push(Part(0x6Ce8c889412944b083D6Ace0c6FffA728a842Fec, 35, 15)); // Alexandra 3.5 1.5
        parts.push(Part(0x2E07aB79A8B8F0D23CaC8431a34a1b2e42c2E24b, 95, 150)); // Alexandre 9.5 15
        parts.push(Part(0x6c0b5f8B9BdB8fB206Da7Cd7E6B16b9dB14B60e2, 50, 110)); // Hippolyte 5 11
        parts.push(Part(0xb6a1d15Bcc1C35A1A67AE06A5197339C1161d0Ca, 15, 15)); // Léo 1.5 1.5
        parts.push(Part(0xccd4f2fe73e7E4757C58F23f0Dd4cdC63082BD54, 15, 15)); // Yannick 1.5 1.5
        parts.push(Part(0x84cEea17EA0466B8d0da339Bca7B3F5629f4338F, 20, 0)); // club 721 2 0
    }

    function shareSalesPart() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");
        require(!saleIsOver, "Sales over");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].salePart > 0){
                _withdraw(parts[i].wallet, balance.mul(parts[i].salePart).div(1000));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function shareRoyaltiesPart() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].royaltiesPart > 0){
                _withdraw(parts[i].wallet, balance.mul(parts[i].royaltiesPart).div(1000));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setSaleIsOver() public onlyOwner{
        saleIsOver = true;
    }

    receive() external payable {}

}