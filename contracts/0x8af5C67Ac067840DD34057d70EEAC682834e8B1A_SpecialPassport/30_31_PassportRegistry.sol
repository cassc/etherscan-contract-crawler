// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract PassportRegistry is Ownable {

    address[] private allPassports;

    function getAllPassports() public view returns (address[] memory) {
        return allPassports;
    }

    function hasPassport(address address_) public view returns (bool)  {
        require(address_ != address(0), "PassportRegistry: address cannot be 0");

        for (uint256 i = 0; i < allPassports.length; i++) {
            if ((ERC721Upgradeable(allPassports[i]).balanceOf(address_) > 0)) {
                return true;
            }
        }

        return false;
    }

    function addPassport(address address_) public onlyOwner {
        require(address_ != address(0), "PassportRegistry: address cannot be 0");
        require(Address.isContract(address_), "PassportRegistry: address is not a contract address");

        for (uint256 i = 0; i < allPassports.length; i++) {
            require(allPassports[i] != address_, "PassportRegistry: address already exists");
        }
        allPassports.push(address_);
    }

    function removePassport(address address_) public onlyOwner {
        require(address_ != address(0), "PassportRegistry: address cannot be 0");
        require(Address.isContract(address_), "PassportRegistry: address is not a contract address");
        for (uint256 i = 0; i < allPassports.length; i++) {
            if (allPassports[i] == address_) {
                allPassports[i] = allPassports[allPassports.length - 1];
                allPassports.pop();
                return;
            }
        }
    }
}