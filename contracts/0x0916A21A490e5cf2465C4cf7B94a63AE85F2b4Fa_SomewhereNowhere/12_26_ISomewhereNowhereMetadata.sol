// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ISomewhereNowhereMetadata {
    error TokenContractAddressIsZeroAddress();

    event TokenContractAddressUpdated(address indexed tokenContractAddress);

    function setTokenContractAddress(address tokenContractAddress) external;

    function getTokenContractAddress() external view returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}