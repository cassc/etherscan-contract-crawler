// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

interface IMetadataHandler {
    
    function getOutputReceiverURL() external view returns (string memory);

    function getAddressLockURL() external view returns (string memory);

    function getOutputReceiverBytes(uint fnftId) external view returns (bytes memory output);

    function getAddressLockBytes(uint fnftId, uint) external view returns (bytes memory output);
    
}