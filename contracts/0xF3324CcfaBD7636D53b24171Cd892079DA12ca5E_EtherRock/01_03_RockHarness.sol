// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// This is a revised version of the original EtherRock contract 0x37504ae0282f5f334ed29b4548646f887977b7cc with all the rock owners and rock properties the same at the time this new contract is being deployed.
// The original contract at 0x37504ae0282f5f334ed29b4548646f887977b7cc had a simple mistake in the buyRock() function. The line:
// require(rocks[rockNumber].currentlyForSale = true);
// Had to have double equals, as follows:
// require(rocks[rockNumber].currentlyForSale == true);
// Therefore in the original contract, anyone could buy anyone elses rock for the same price the owner purchased it for (regardless of whether the owner chose to sell it or not)

import "@openzeppelin/contracts/access/Ownable.sol";

contract EtherRock is Ownable {
    bool public rockIsForSale = false;
    uint256 public sellableRockNumber = 69;
    uint256 public sellableRockPriceGwei = 2;

    constructor() {}

    function getRockInfo(uint256 rockNumber)
        public
        returns (
            address,
            bool,
            uint256,
            uint256
        )
    {
        if (rockNumber == sellableRockNumber) {
            return (address(0), rockIsForSale, sellableRockPriceGwei, 0);
        }

        return (address(0), false, 0, 0);
    }

    function buyRock(uint256 rockNumber) public payable {
        require(rockNumber == sellableRockNumber);
        require(rockIsForSale);
        require(msg.value == sellableRockPriceGwei);

        rockIsForSale = false;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setState(bool isForSale, uint256 price) public onlyOwner {
        rockIsForSale = isForSale;
        sellableRockPriceGwei = price;
    }
}