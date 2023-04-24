//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract AddressPrefix{
    
    using Strings for address;

    function refIdfromAdd(address user_)public pure returns(string memory){
        string memory userAddress;
        userAddress = addressToString(user_);
        return string(abi.encodePacked(getFirstFiveChars(userAddress) , getLastFiveChars(userAddress)));
    }

    function addressToString(address _address) public pure returns (string memory) {
        return _address.toHexString();
    }

    function getFirstFiveChars(string memory str) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length >= 5, "String length is less than 5");

        bytes memory result = new bytes(5);
        for (uint i = 0; i < 5; i++) {
            result[i] = strBytes[i+2];
        }
        return string(result);
    }

    function getLastFiveChars(string memory str) public pure returns (string memory) {
        require(bytes(str).length >= 5, "String is too short");
        return substring(str, bytes(str).length - 5, 5);
    }

    function substring(string memory str, uint startIndex, uint length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex + length <= strBytes.length, "Substring out of bounds");
        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = strBytes[startIndex + i];
        }
        return string(result);
    }

}