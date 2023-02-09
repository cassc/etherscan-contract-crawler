// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Base {
    constructor () {

    }

    //0x20 - length
    //0x53c6eaee8696e4c5200d3d231b29cc6a40b3893a5ae1536b0ac08212ffada877
    bytes constant notFoundMark = abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked("404-method-not-found")))))));


    //return the payload of returnData, stripe the leading length
    function returnAsm(bool isRevert, bytes memory returnData) pure internal {
        assembly{
            let length := mload(returnData)
            switch isRevert
            case 0x00{
                return (add(returnData, 0x20), length)
            }
            default{
                revert (add(returnData, 0x20), length)
            }
        }
    }

    modifier nonPayable(){
        require(msg.value == 0, "nonPayable");
        _;
    }

}