// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev This contract is used to represent `CryptoPunksMarket` and interact with CryptoPunk NFTs.
 */
interface ICryptoPunk {
    function punkIndexToAddress(uint256 punkIndex) external view returns (address);

    function transferPunk(address to, uint256 punkIndex) external;
}