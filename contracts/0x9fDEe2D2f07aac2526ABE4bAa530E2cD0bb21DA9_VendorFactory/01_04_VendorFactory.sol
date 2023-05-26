//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface ITokenVendor {
    function initialize(uint buyPrice, uint sellPrice) external;
}

contract VendorFactory is Context, Ownable{

    event VendorCreated(address indexed token, address vendor);
    mapping (address => address) supported_vendor;

    function addSupport(address token, address vendor) public onlyOwner() {
        supported_vendor[token] = vendor;
    }

    function createVendor(uint buyPrice, uint sellPrice, address tokenAddress) public payable returns (address new_vendor) {
        //require(buyPrice >= sellPrice, "buyPrice must be larger than sellPrice")
        require((supported_vendor[tokenAddress] != address(0)), "Token is not supported.");
        new_vendor = Clones.clone(supported_vendor[tokenAddress]);
        ITokenVendor(new_vendor).initialize(buyPrice, sellPrice);
        Ownable(new_vendor).transferOwnership(_msgSender());
        payable(new_vendor).transfer(msg.value);
        emit VendorCreated(tokenAddress, new_vendor);
    }    


}