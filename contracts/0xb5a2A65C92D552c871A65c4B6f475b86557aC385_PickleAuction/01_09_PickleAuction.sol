// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IPicklePeople {
    function mint(address _to) external;
}

contract PickleAuction is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public beneficiary1;
    address public beneficiary2;
    IPicklePeople public picklePeopleNFT;
    uint public remaining = 48;
    uint public minPrice = 1 ether / 80;
    uint public duration = 15 minutes;
    uint public delta = 15; 
    uint public lastPrice = 1 ether / 40;
    uint public lastTimestamp = 0;

    event Mint(address wallet, uint256 price);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        beneficiary1 = 0x3bC076F574648beA112BdD4E1aB4c6Ac178E7116;
        beneficiary2 = 0xb4005DB54aDecf669BaBC3efb19B9B7E3978ebc2;
        picklePeopleNFT = IPicklePeople(0x13f0f522ce1dBe2025DadC332E11d6b511614bc0); // mainnet
    }

// Mint

    function mint(address _to) public payable {
        require(lastTimestamp > 0, "Not started");
        require(price() >= minPrice, "Pricing Error");
        require(msg.value >= price(), 'Insufficient payment');
        lastPrice = price();
        lastTimestamp = block.timestamp;
        remaining--;
        uint half = msg.value / 2;
        Address.sendValue(payable(beneficiary1), half);
        Address.sendValue(payable(beneficiary2), msg.value - half);
        picklePeopleNFT.mint(_to);
        emit Mint(_to, lastPrice);
    }

// View

    function price() public view returns (uint) {
        uint p = lastPrice * delta / 100;
        uint x = block.timestamp - lastTimestamp;
        uint d = duration;
        if ((p * x / d) > lastPrice + p)
            return minPrice;
        uint result = (lastPrice + p) - (p * x / d);
        return Math.max(minPrice, result);
    }

// Admin

    function start() public onlyRole(MINTER_ROLE) {
        lastTimestamp = block.timestamp;
    }

    function setBeneficiary1(address _addr) public onlyRole(MINTER_ROLE){
        beneficiary1 = _addr;
    }

    function setBeneficiary2(address _addr) public onlyRole(MINTER_ROLE){
        beneficiary2 = _addr;
    }

    function withdraw(address _addr)public onlyRole(MINTER_ROLE) {
        Address.sendValue(payable(_addr), address(this).balance);
    }

    function increaseRemaining(uint _count) public onlyRole(MINTER_ROLE){
        remaining += _count;
    }

    function setMinPrice(uint _price) public onlyRole(MINTER_ROLE){
        minPrice = _price;
    }

    function setDuration(uint _seconds) public onlyRole(MINTER_ROLE){
        duration = _seconds;
    }
    function setDelta(uint _percent) public onlyRole(MINTER_ROLE){
        delta = _percent;
    }

    function setLastPrice(uint _price) public onlyRole(MINTER_ROLE){
        lastPrice = _price;
    }

    function setLastTimestamp(uint _timestamp) public onlyRole(MINTER_ROLE){
        lastTimestamp = _timestamp;
    }

}