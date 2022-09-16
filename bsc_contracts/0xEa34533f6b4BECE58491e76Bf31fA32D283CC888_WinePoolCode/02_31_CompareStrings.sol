// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library CompareStrings {

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b) internal pure returns(bool){
        return memcmp(bytes(a), bytes(b));
    }

    function isEmpty(string memory a) internal pure returns(bool){
        return strcmp(a, "");
    }

}