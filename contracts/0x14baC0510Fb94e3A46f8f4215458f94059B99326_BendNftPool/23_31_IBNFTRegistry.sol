// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IBNFTRegistry {
    function getBNFTAddresses(address nftAsset) external view returns (address bNftProxy, address bNftImpl);
}