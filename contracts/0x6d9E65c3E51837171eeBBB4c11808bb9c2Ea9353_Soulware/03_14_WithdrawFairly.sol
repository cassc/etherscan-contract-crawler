// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WithdrawFairly is Ownable {
    using SafeMath for uint256;

    struct Part {
        address wallet;
        uint256 salePart;
        uint256 royaltiesPart;
    }

    Part[] public parts;

    constructor(){
        parts.push(Part(0x82acCD007449E15dD8566D8199B8C9593403517b, 225, 150));
        parts.push(Part(0x65720Bb1f5d0bAD279e6fb3e03B116771D0321FC, 350, 375));
        parts.push(Part(0x69F3c8695CCC7c77EdaA9459d9Dbc9A444Cf3c5b, 85, 120));
        parts.push(Part(0x7E0EDC5639b84E5F2072c968f5c424e2b58A5A1A, 140, 60));
        parts.push(Part(0x6Ce8c889412944b083D6Ace0c6FffA728a842Fec, 35, 15));
        parts.push(Part(0x2E07aB79A8B8F0D23CaC8431a34a1b2e42c2E24b, 105, 150));
        parts.push(Part(0x6c0b5f8B9BdB8fB206Da7Cd7E6B16b9dB14B60e2, 50, 120));
        parts.push(Part(0xccd4f2fe73e7E4757C58F23f0Dd4cdC63082BD54, 10, 10));
    }

    function shareSalesPart() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");

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

    receive() external payable {}

}