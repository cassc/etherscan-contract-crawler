// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";

// @author: NFT Studios - Buildtree

abstract contract ProtectedMintBurn is Ownable {
    mapping(address => bool) public allowedMinter;
    mapping(address => bool) public allowedBurner;

    constructor() {}

    modifier onlyMinter() {
        require(allowedMinter[msg.sender] || owner() == msg.sender, "ProtectedMintBurn: caller is not a minter");

        _;
    }

    modifier onlyBurner() {
        require(allowedBurner[msg.sender], "ProtectedMintBurn: caller is not a burner");

        _;
    }

    function addMinter(address _minter) external onlyOwner {
        allowedMinter[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner {
        allowedMinter[_minter] = false;
    }

    function addBurner(address _burner) external onlyOwner {
        allowedBurner[_burner] = true;
    }

    function removeBurner(address _burner) external onlyOwner {
        allowedBurner[_burner] = false;
    }
}