// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetFixedSupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract ERC20Factory is OwnableUpgradeable {
    address immutable tokenImplementation;
    address feeTaker; // Enable the ability to charge for factory use.
    uint256 price; // Enable setting a price for the service.

    constructor() {
        OwnableUpgradeable.__Ownable_init_unchained(); // Set the initial owner.

        tokenImplementation = address(new ERC20PresetFixedSupplyUpgradeable());
        feeTaker = 0x92Ce0aC59ACCA8Ec7BdC5085AA17866a5D133a6A; // Initial fee taker address.
        price = 0; // Price starting a free.
    }

    function createToken(string calldata name, string calldata symbol, uint256 initialSupply) payable external returns (address) {
        // If we have a price set ensure the correct price has been paid.
        require(msg.value >= price, "Please send enough ether");

        // If the user sent a tip send it to the creator address.
        if(msg.value > 0) {
            address payable creator = payable(feeTaker);
            creator.transfer(address(this).balance);
        }

        // Lets create our token!
        address clone = Clones.clone(tokenImplementation);
        ERC20PresetFixedSupplyUpgradeable(clone).initialize(name, symbol, initialSupply, msg.sender);
        return clone;
    }

    function changeFeeTaker (address newAddress) public onlyOwner() returns(address) {
        feeTaker = newAddress;
        return feeTaker;
    }
    function getFeeTaker() public view returns(address) {
        return feeTaker;
    }

    function changePrice (uint256 newPrice) public onlyOwner() returns(uint256) {
        price = newPrice;
        return price;
    }

    function getPrice() public view returns(uint256) {
        return price;
    }

}