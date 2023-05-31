// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library PetsEvents {
    event PetAirdropped(address indexed _to, uint256 indexed _quantity);
    event PetPurchased(address indexed _to, uint256 _quantity, uint256 _value);
}