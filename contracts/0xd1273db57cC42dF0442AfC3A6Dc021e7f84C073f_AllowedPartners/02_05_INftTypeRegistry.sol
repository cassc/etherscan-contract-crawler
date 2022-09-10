// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface INftTypeRegistry {
    function setNftType(bytes32 _nftType, address _nftWrapper) external;

    function getNftTypeWrapper(bytes32 _nftType) external view returns (address);
}