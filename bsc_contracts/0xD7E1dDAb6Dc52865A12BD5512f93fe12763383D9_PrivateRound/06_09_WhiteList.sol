// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract WhiteList is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private whiteList;

    constructor() Ownable() {}

    // check if address is whitelisted
    function isAddressInWhiteList(address _address) public view returns (bool) {
        return whiteList.contains(_address);
    }

    // add multi address to whitelist
    function addToWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
           whiteList.add(_addresses[i]); 
        }
    }

    // remove multi address from whitelist
    function removeFromWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteList.remove(_addresses[i]);
        }
    }

    // get whitelist address
    function getWhitelist() public view returns (address[] memory) {
        address[] memory result = new address[](whiteList.length());
        for (uint256 i = 0; i < whiteList.length(); i++) {
            result[i] = whiteList.at(i);
        }
        return result;
    }
}